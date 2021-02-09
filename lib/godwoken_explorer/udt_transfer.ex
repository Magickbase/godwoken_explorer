defmodule GodwokenExplorer.UdtTransfer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "udt_transfers" do
    field :amount, :decimal
    field :fee, :decimal

    belongs_to(:transaction, GodwokenExplorer.Transaction, foreign_key: :tx_hash, references: :hash)
    belongs_to(:udt, GodwokenExplorer.Udt, foreign_key: :udt_id, references: :id)

    timestamps()
  end

  @doc false
  def changeset(udt_transfer, attrs) do
    udt_transfer
    |> cast(attrs, [:tx_hash, :udt_id, :amount, :fee])
    |> validate_required([:tx_hash, :udt_id, :amount, :fee])
  end
end
