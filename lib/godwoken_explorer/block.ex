defmodule GodwokenExplorer.Block do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  @fields [:hash, :parent_hash, :number, :timestamp, :miner_id, :transaction_count, :finalized_tx_hash, :finalized_at]
  @required_fields [:hash, :parent_hash, :number, :timestamp, :miner_id, :transaction_count]

  @primary_key {:hash, :binary, autogenerate: false}
  schema "blocks" do
    field :number, :integer
    field :parent_hash, :binary
    field :timestamp, :utc_datetime_usec
    field :miner_id, :binary
    field :finalized_at, :utc_datetime_usec
    field :finalized_tx_hash, :binary
    field :transaction_count, :integer

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
end
