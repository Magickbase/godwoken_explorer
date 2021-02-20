defmodule GodwokenExplorer.UDTTransfer do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  schema "udt_transfers" do
    field :amount, :decimal
    field :fee, :decimal
    field :tx_hash, :binary

    belongs_to(:transaction, GodwokenExplorer.Transaction, foreign_key: :tx_hash, references: :hash, define_field: false)
    belongs_to(:udt, GodwokenExplorer.UDT, foreign_key: :udt_id, references: :id)

    timestamps()
  end

  @doc false
  def changeset(udt_transfer, attrs) do
    udt_transfer
    |> cast(attrs, [:udt_id, :amount, :fee])
    |> validate_required([:udt_id, :amount, :fee])
  end

  def create_udt_transfer(attrs) do
    %UDTTransfer{}
    |> UDTTransfer.changeset(attrs)
    |> Ecto.Changeset.put_change(:tx_hash, attrs[:hash])
    |> Ecto.Changeset.put_change(:udt_id, attrs[:udt_id])
    |> Repo.insert!()
  end
end
