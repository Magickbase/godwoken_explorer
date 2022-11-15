defmodule GodwokenExplorer.Block do
  @moduledoc """
  Block structure with their data.
  """
  use GodwokenExplorer, :schema

  require Logger

  alias GodwokenExplorer.Chain.Cache.Blocks
  alias GodwokenExplorer.Chain.Events.Publisher
  alias GodwokenExplorer.Chain.Hash

  @typedoc """
   *  `hash` - The `t:GowokenExplorer.Chain.Hash.Full.t/0` that is current block hash.
   *  `nubmer` - The block number, start with 0.
   *  `parent_hash` - The `t:GowokenExplorer.Chain.Hash.Full.t/0` that is parent block hash.
   *  `timestamp` - When the block was collated.
   *  `status` - Committed means block submit to layer1(CKB) and can be challenged;Finalized means block can't be challenged.
   *  `transaction_count` - The block contains transction count.
   *  `layer1_tx_hash` - Finalized at whic layer1 transaction hash.
   *  `layer1_block_number` - Finalized at whic layer1 block number.
   *  `size` - The size of the block in bytes.
   *  `gas_limit` - Gas limit of this block.
   *  `gas_used` - Actual used gas.
   *  `logsBloom` - the [Bloom filter](https://en.wikipedia.org/wiki/Bloom_filter) for the logs of the block.
   *  `registry_id` - The block producer registers by which account id.
   *  `producer_address` - The block produced by which account.
  """
  @type t :: %__MODULE__{
          hash: Hash.Full.t(),
          number: non_neg_integer(),
          parent_hash: Hash.Full.t(),
          timestamp: DateTime.t(),
          status: String.t(),
          transaction_count: non_neg_integer(),
          layer1_tx_hash: Hash.Full.t(),
          layer1_block_number: non_neg_integer(),
          size: non_neg_integer(),
          gas_limit: Decimal.t(),
          gas_used: Decimal.t(),
          logs_bloom: binary(),
          registry_id: non_neg_integer(),
          producer_address: Hash.Address.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @fields [
    :hash,
    :parent_hash,
    :number,
    :timestamp,
    :status,
    :registry_id,
    :producer_address,
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
    :transaction_count
  ]

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:hash, Hash.Full, autogenerate: false}
  schema "blocks" do
    field :number, :integer
    field :parent_hash, Hash.Full
    field :timestamp, :utc_datetime_usec
    field :status, Ecto.Enum, values: [:committed, :finalized]
    field :transaction_count, :integer
    field :layer1_tx_hash, Hash.Full
    field :layer1_block_number, :integer
    field :size, :integer
    field :gas_limit, :decimal
    field :gas_used, :decimal
    field :logs_bloom, :binary
    field :registry_id, :integer
    field :producer_address, Hash.Address

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
      where: b.hash == ^downcase_param
    )
    |> Repo.one()
  end

  def find_by_number_or_hash(number) when is_binary(number) or is_integer(number) do
    case Integer.parse(number) do
      {block_number, ""} ->
        from(b in Block,
          where: b.number == ^block_number
        )
        |> Repo.one()

      :error ->
        nil
    end
  end

  def latest_10_records do
    case Blocks.all() do
      blocks when is_list(blocks) and length(blocks) == 10 ->
        blocks
        |> Enum.map(fn b ->
          b |> Map.take([:hash, :number, :timestamp, :transaction_count])
        end)

      _ ->
        from(b in Block,
          select: %{
            hash: b.hash,
            number: b.number,
            timestamp: b.timestamp,
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

    updated_blocks = block_query |> Repo.all(timeout: :infinity)

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
      |> __MODULE__.changeset(%{layer1_block_number: l1_block_number, layer1_tx_hash: l1_tx_hash})
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
      __MODULE__.changeset(block, %{
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
end
