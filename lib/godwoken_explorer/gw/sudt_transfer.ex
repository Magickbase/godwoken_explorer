defmodule GodwokenExplorer.GW.SudtTransfer do
  @moduledoc """
  The sudt transfer type of Godwoken log.

  When we recieve this type log, we will update account's udt balance.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias GodwokenExplorer.Chain.Hash

  @typedoc """
   *  `amount` - Transfer amount.
   *  `to_registry_id` - The receiver account register by account id.
   *  `to_address` - The receiver account address.
   *  `from_registry_id` - The from account register by account id.
   *  `from_address` - The `t:GowokenExplorer.Chain.Hash.Address.t/0` that is the from account address.
   *  `log_index` - Godwoken Log index.
   *  `udt_id` - The udt foreign key.
   *  `transaction_hash` - The transaction foreign key.
  """
  @type t :: %__MODULE__{
          amount: Decimal.t(),
          to_registry_id: non_neg_integer(),
          to_address: Hash.Address.t(),
          from_registry_id: non_neg_integer(),
          from_address: Hash.Address.t(),
          log_index: non_neg_integer(),
          udt_id: non_neg_integer(),
          transaction: %Ecto.Association.NotLoaded{} | Transaction.t(),
          transaction_hash: Chain.Hash.Full.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @derive {Jason.Encoder, except: [:__meta__]}
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
