defmodule GodwokenExplorer.GW.Log do
  use Ecto.Schema
  import Ecto.Changeset

  alias GodwokenExplorer.Chain.{Data, Hash}

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
