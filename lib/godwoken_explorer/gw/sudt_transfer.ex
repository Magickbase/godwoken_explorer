defmodule GodwokenExplorer.GW.SudtTransfer do
  use Ecto.Schema
  import Ecto.Changeset

  alias GodwokenExplorer.Chain.Hash

  @primary_key false
  schema "gw_sudt_transfers" do
    field :amount, :decimal
    field :from_registry_id, :integer
    field :from_address, Hash.Address
    field :log_index, :integer, primary_key: true
    field :to_address, Hash.Address
    field :to_registry_id, :integer
    field :udt_id, :integer

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :transaction_hash,
      primary_key: true,
      references: :hash,
      type: Hash.Full
    )

    timestamps()
  end

  @doc false
  def changeset(sudt_transfer, attrs) do
    sudt_transfer
    |> cast(attrs, [
      :transaction_hash,
      :log_index,
      :udt_id,
      :from_address,
      :to_address,
      :amount,
      :from_registry_id,
      :to_registry_id
    ])
    |> validate_required([
      :transaction_hash,
      :log_index,
      :udt_id,
      :from_address,
      :to_address,
      :amount
    ])
  end
end
