defmodule GodwokenExplorer.Block do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:hash, :binary, autogenerate: false}
  schema "blocks" do
    field :number, :integer
    field :parent_block_hash, :binary
    field :timestamp, :utc_datetime_usec
    field :finalized_at, :utc_datetime_usec
    field :finalized_tx_hash, :binary
    field :transaction_count, :integer

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:hash, :parent_hash, :number, :timestamp, :transaction_count, :finalized_hash, :finalized_at])
    |> validate_required([:hash, :parent_hash, :number, :timestamp, :transaction_count, :finalized_hash, :finalized_at])
  end

  def create_block(attrs \\ %{}) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end
end
