defmodule GodwokenExplorer.WithdrawalRequest do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  alias GodwokenExplorer.Chain.Hash

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "withdrawal_requests" do
    field :hash, :binary
    field :nonce, :integer
    field :capacity, :decimal
    field :amount, :decimal
    field :sudt_script_hash, Hash.Full
    field :account_script_hash, Hash.Full
    field :owner_lock_hash, Hash.Full
    field :fee_amount, :decimal
    field :block_hash, Hash.Full
    field :block_number, :integer
    field :chain_id, :integer
    field :registry_id, :integer

    belongs_to(:udt, GodwokenExplorer.UDT,
      foreign_key: :udt_id,
      references: :id,
      type: :integer
    )

    timestamps()
  end

  @doc false
  def changeset(withdrawal_request, attrs) do
    withdrawal_request
    |> cast(attrs, [
      :hash,
      :account_script_hash,
      :amount,
      :capacity,
      :owner_lock_hash,
      :sudt_script_hash,
      :udt_id,
      :block_hash,
      :nonce,
      :block_number,
      :fee_amount,
      :chain_id,
      :registry_id
    ])
    |> validate_required([
      :hash,
      :account_script_hash,
      :amount,
      :capacity,
      :owner_lock_hash,
      :sudt_script_hash,
      :nonce,
      :block_hash,
      :block_number
    ])
    |> unique_constraint([:account_script_hash, :nonce])
  end

  def create_withdrawal_request(attrs) do
    %WithdrawalRequest{}
    |> WithdrawalRequest.changeset(attrs)
    |> Repo.insert()
  end
end
