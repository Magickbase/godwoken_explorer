defmodule GodwokenExplorer.GW.Log do
  use Ecto.Schema
  import Ecto.Changeset

  alias GodwokenExplorer.Chain.{Data, Hash}

  schema "gw_logs" do
    field :account_id, :integer
    field :data, Data
    field :service_flag, :integer

    field(:type, Ecto.Enum,
      values: [:sudt_transfer, :sudt_pay_fee, :polyjuice_system, :polyjuce_user]
    )

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :transaction_hash,
      references: :hash,
      type: Hash.Full
    )

    timestamps()
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:transaction_hash, :account_id, :service_flag, :data, :type])
    |> validate_required([:transaction_hash, :account_id, :service_flag, :data, :type])
  end
end
