defmodule GodwokenExplorer.Block do
  use GodwokenExplorer, :schema

  require Logger

  alias GodwokenExplorer.Chain.Cache.Blocks
  alias GodwokenExplorer.Chain.Events.Publisher

  @fields [
    :hash,
    :parent_hash,
    :number,
    :timestamp,
    :status,
    :aggregator_id,
    :transaction_count,
    :layer1_tx_hash,
    :layer1_block_number,
    :size,
    :gas_limit,
    :gas_used,
    :logs_bloom
  ]
  @required_fields [
    :hash,
    :parent_hash,
    :number,
    :timestamp,
    :status,
    :aggregator_id,
    :transaction_count
  ]

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:hash, :binary, autogenerate: false}
  schema "blocks" do
    field :number, :integer
    field :parent_hash, :binary
    field :timestamp, :utc_datetime_usec
    field :status, Ecto.Enum, values: [:committed, :finalized], default: :committed
    field :aggregator_id, :integer
    field :transaction_count, :integer
    field :layer1_tx_hash, :binary
    field :layer1_block_number, :integer
    field :size, :integer
    field :gas_limit, :decimal
    field :gas_used, :decimal
    field :logs_bloom, :binary
    field :difficulty, :decimal
    field :total_difficulty, :decimal
    field :nonce, :binary
    field :sha3_uncles, :binary
    field :state_root, :binary
    field :extra_data, :binary

    has_one :account, Account, foreign_key: :id, references: :aggregator_id
    has_many :transactions, GodwokenExplorer.Transaction, foreign_key: :block_hash

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:hash, name: :blocks_pkey)
  end

  def create_block(attrs \\ %{}) do
    %Block{}
    |> changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  def find_by_number_or_hash("0x" <> _ = param) do
    downcase_param = String.downcase(param)

    from(b in Block,
      join: a in assoc(b, :account),
      preload: [account: a],
      where: b.hash == ^downcase_param
    )
    |> Repo.one()
  end

  def find_by_number_or_hash(number) when is_binary(number) or is_integer(number) do
    from(b in Block,
      join: a in assoc(b, :account),
      preload: [account: a],
      where: b.number == ^number
    )
    |> Repo.one()
  end

  def latest_10_records do
    case Blocks.all() do
      blocks when is_list(blocks) and length(blocks) == 10 ->
        blocks
        |> Enum.map(fn b ->
          b |> Map.take([:hash, :number, :inserted_at, :transaction_count])
        end)

      _ ->
        from(b in "blocks",
          select: %{
            hash: b.hash,
            number: b.number,
            timestamp: b.inserted_at,
            transaction_count: b.transaction_count
          },
          order_by: [desc: b.number],
          limit: 10
        )
        |> Repo.all()
    end
  end

  def transactions_count_per_second(interval \\ 10) do
    with timestamp_with_tx_count when length(timestamp_with_tx_count) != 0 <-
           from(b in Block,
             select: %{timestamp: b.timestamp, tx_count: b.transaction_count},
             order_by: [desc: b.number],
             limit: ^interval
           )
           |> Repo.all(),
         all_tx_count when all_tx_count != 0 <-
           timestamp_with_tx_count
           |> Enum.map(fn %{timestamp: _, tx_count: tx_count} -> tx_count end)
           |> Enum.sum() do
      %{timestamp: last_timestamp, tx_count: _} = timestamp_with_tx_count |> List.first()
      %{timestamp: first_timestamp, tx_count: _} = timestamp_with_tx_count |> List.last()

      if NaiveDateTime.diff(last_timestamp, first_timestamp) == 0 do
        0.0
      else
        (all_tx_count / NaiveDateTime.diff(last_timestamp, first_timestamp)) |> Float.floor(1)
      end
    else
      _ -> 0.0
    end
  end

  def update_blocks_finalized(latest_finalized_block_number) do
    block_query =
      from(b in Block,
        where: b.number <= ^latest_finalized_block_number and b.status == :committed
      )

    updated_blocks = block_query |> Repo.all()

    {updated_blocks_number, nil} =
      block_query
      |> Repo.update_all(set: [status: "finalized", updated_at: DateTime.now!("Etc/UTC")])

    if updated_blocks_number > 0 do
      updated_blocks
      |> Enum.each(fn b ->
        Publisher.broadcast(
          [
            {:blocks,
             %{
               number: b.number,
               l1_block_number: b.layer1_block_number,
               l1_tx_hash: b.layer1_tx_hash,
               status: "finalized"
             }}
          ],
          :realtime
        )

        broadcast_tx_of_block(b.hash, b.layer1_block_number)
      end)
    end
  end

  def bind_l1_l2_block(l2_block_number, l1_block_number, l1_tx_hash) do
    with %Block{hash: hash} = block <- Repo.get_by(Block, number: l2_block_number) do
      block
      |> Ecto.Changeset.change(%{layer1_block_number: l1_block_number, layer1_tx_hash: l1_tx_hash})
      |> Repo.update!()

      Publisher.broadcast(
        [
          {:blocks,
           %{
             number: l2_block_number,
             l1_block_number: l1_block_number,
             l1_tx_hash: l1_tx_hash,
             status: block.status
           }}
        ],
        :realtime
      )

      broadcast_tx_of_block(hash, l1_block_number)

      l1_block_number
    end
  end

  defp broadcast_tx_of_block(l2_block_hash, l1_block_number) do
    query =
      from(t in Transaction,
        join: b in Block,
        on: b.number == t.block_number,
        where: t.block_hash == ^l2_block_hash,
        select: %{hash: t.hash, status: b.status}
      )

    Repo.all(query)
    |> Enum.each(fn tx ->
      Publisher.broadcast(
        [
          {:transactions,
           %{tx_hash: tx.hash, l1_block_number: l1_block_number, status: tx.status}}
        ],
        :realtime
      )
    end)
  end

  def find_last_bind_l1_block() do
    from(b in Block,
      where: not is_nil(b.layer1_block_number),
      order_by: [desc: :number],
      limit: 1
    )
    |> Repo.one()
  end

  def reset_layer1_bind_info!(layer1_block_number) do
    from(b in Block, where: b.layer1_block_number == ^layer1_block_number)
    |> Repo.all()
    |> Enum.each(fn block ->
      Ecto.Changeset.change(block, %{
        layer1_block_number: nil,
        layer1_tx_hash: nil,
        status: :committed
      })
      |> Repo.update!()
    end)
  end

  def rollback!(hash) do
    Repo.get(__MODULE__, hash) |> Repo.delete!()
    from(t in Transaction, where: t.block_hash == ^hash) |> Repo.delete_all()
  end

  def miner_hash(block) do
    if block.account.type in [:eth_user, :tron_user] do
      block.account.eth_address
    else
      block.account.short_address
    end
  end
end
