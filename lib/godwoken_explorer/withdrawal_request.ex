defmodule GodwokenExplorer.WithdrawalRequest do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  schema "withdrawal_requests" do
    field :nonce, :integer
    field :capacity, :decimal
    field :amount, :decimal
    field :sell_amount, :decimal
    field :sell_capacity, :decimal
    field :sudt_script_hash, :binary
    field :account_script_hash, :binary
    field :owner_lock_hash, :binary
    field :payment_lock_hash, :binary
    field :fee_amount, :decimal
    field :fee_udt_id, :integer
    field :udt_id, :integer
    field :block_hash, :binary
    field :block_number, :integer

    belongs_to(:udt, GodwokenExplorer.UDT,
      foreign_key: :udt_id,
      references: :id,
      define_field: false
    )

    timestamps()
  end

  @doc false
  def changeset(withdrawal_request, attrs) do
    withdrawal_request
    |> cast(attrs, [
      :account_script_hash,
      :amount,
      :capacity,
      :owner_lock_hash,
      :payment_lock_hash,
      :sell_amount,
      :sell_capacity,
      :sudt_script_hash,
      :udt_id,
      :block_hash,
      :nonce,
      :block_number,
      :fee_amount,
      :fee_udt_id
    ])
    |> validate_required([
      :account_script_hash,
      :amount,
      :capacity,
      :owner_lock_hash,
      :payment_lock_hash,
      :sell_amount,
      :sell_capacity,
      :sudt_script_hash,
      :nonce,
      :block_hash,
      :block_number
    ])
  end

  def create_withdrawal_request(attrs) do
    %WithdrawalRequest{}
    |> WithdrawalRequest.changeset(attrs)
    |> Repo.insert()
  end
end
