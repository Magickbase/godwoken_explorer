defmodule GodwokenExplorer.GW.SudtPayFee do
  use Ecto.Schema
  import Ecto.Changeset

  alias GodwokenExplorer.Chain.Hash

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key false
  schema "gw_sudt_pay_fees" do
    field :amount, :decimal
    field :block_producer_registry_id, :integer
    field :block_producer_address, Hash.Address
    field :from_registry_id, :integer
    field :from_address, Hash.Address
    field :log_index, :integer, primary_key: true
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
  def changeset(sudt_pay_fee, attrs) do
    sudt_pay_fee
    |> cast(attrs, [
      :transaction_hash,
      :log_index,
      :udt_id,
      :from_address,
      :block_producer_address,
      :amount,
      :from_registry_id,
      :block_producer_registry_id
    ])
    |> validate_required([
      :transaction_hash,
      :log_index,
      :udt_id,
      :from_address,
      :block_producer_address,
      :amount
    ])
  end
end
