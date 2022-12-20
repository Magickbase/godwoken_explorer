defmodule GodwokenExplorer.WithdrawalRequest do
  @moduledoc """
  Withdrawal requests fetch from layer2.
  """

  use GodwokenExplorer, :schema

  import Ecto.Changeset

  alias GodwokenExplorer.Chain.Hash

  @typedoc """
     * `hash` - Withdrawal hash at layer2.
     * `nonce` - Withdrawal nonce at layer2.
     * `capacity` - Layer1 transaction's output's capacity or ckb withdrawal amount.
     * `amount` - Withdrawal amount.
     * `sudt_script_hash` - The udt of layer1's script hash.
     * `account_script_hash` - Layer2 account script hash.
     * `owner_lock_hash` - Layer1 owner's lock hash.
     * `fee_amount` - Withdrawal fee.
     * `layer1_block_number` - Deposit at which layer1 block.
     * `layer1_tx_hash` - Deposit at which layer1 transaction.
     * `layer1_output_index` - Deposit transaction's output index.
     * `block_hash` - Withdraw at which layer2 block.
     * `block_number` - Withdraw at which layer2 block.
     * `chain_id` - Which godwoken chain.
     * `registry_id` - Which godwoken registrer.
     * `udt_id` - The UDT table foreign key.
  """

  @type t :: %__MODULE__{
          hash: Hash.Full.t(),
          nonce: non_neg_integer(),
          capacity: Decimal.t(),
          amount: Decimal.t(),
          sudt_script_hash: Hash.Full.t(),
          account_script_hash: Hash.Full.t(),
          owner_lock_hash: Hash.Full.t(),
          fee_amount: Decimal.t(),
          block_hash: Hash.Full.t(),
          block_number: non_neg_integer(),
          chain_id: non_neg_integer(),
          registry_id: non_neg_integer(),
          udt_id: non_neg_integer(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "withdrawal_requests" do
    field :hash, Hash.Full
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
