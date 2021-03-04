defmodule GodwokenExplorer.Block do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  @fields [:hash, :parent_hash, :number, :timestamp, :status, :aggregator_id, :transaction_count, :layer1_tx_hash, :layer1_block_number, :size, :tx_fees, :average_gas_price]
  @required_fields [:hash, :parent_hash, :number, :timestamp, :status, :aggregator_id, :transaction_count]

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
    field :tx_fees, :integer
    field :average_gas_price, :decimal

    has_many :transactions, GodwokenExplorer.Transaction, foreign_key: :block_hash

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def create_block(attrs \\ %{}) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end

  def get_next_number do
    case Repo.one(from block in Block, order_by: [desc: block.number], limit: 1) do
      %Block{number: number} -> number + 1
      nil -> 0
    end
  end

  def latest_10_records do
    query = from(b in "blocks",
          select: %{hash: b.hash, number: b.number, timestamp: b.timestamp, tx_count: b.transaction_count},
          order_by: [desc: b.number],
          limit: 10
          )

    Repo.all(query)
  end

  def update_blocks_finalized(latest_finalized_block_number) do
    from(b in Block, where: b.number <= ^latest_finalized_block_number and b.status == :committed)
    |> Repo.update_all(set: [status: "finalized", updated_at: DateTime.now!("Etc/UTC")])
    from(t in Transaction, where: t.block_number <= ^latest_finalized_block_number and t.status == :unfinalized)
    |> Repo.update_all(set: [status: "finalized", updated_at: DateTime.now!("Etc/UTC")])
  end
end
