defmodule GodwokenExplorer.GW.Log do
  @moduledoc """
  Godwoken transaction logs

  Fetch from rpc `gw_get_transaction_receipt`.Source code: https://github.com/godwokenrises/godwoken/blob/develop/crates/utils/src/script_log.rs#L7-L37
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias GodwokenExplorer.Chain.{Data, Hash}

  @typedoc """
   *  `account_id` - The account foreign key.
   *  `data` - The `t:GowokenExplorer.Chain.Data.t/0` that is the log data.
   *  `service_flag` - Godwoken log use this field to filter type.
   *  `index` - Godwoken Log index.
   *  `type` - The type of Godwoken log.
   *  `transaction_hash` - The transaction foreign key.
  """
  @type t :: %__MODULE__{
          account_id: non_neg_integer(),
          data: Data.t(),
          service_flag: non_neg_integer(),
          index: non_neg_integer(),
          type: String.t(),
          transaction: %Ecto.Association.NotLoaded{} | Transaction.t(),
          transaction_hash: Chain.Hash.Full.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key false
  schema "gw_logs" do
    field :account_id, :integer
    field :data, Data
    field :service_flag, :integer
    field :index, :integer, primary_key: true

    field(:type, Ecto.Enum,
      values: [:sudt_transfer, :sudt_pay_fee, :polyjuice_system, :polyjuce_user]
    )

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :transaction_hash,
      primary_key: true,
      references: :hash,
      type: Hash.Full
    )

    timestamps()
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:transaction_hash, :account_id, :service_flag, :data, :type, :index])
    |> validate_required([:transaction_hash, :account_id, :service_flag, :data, :type, :index])
  end
end
