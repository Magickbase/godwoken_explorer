defmodule GodwokenExplorer.Polyjuice do
  use Ecto.Schema
  import Ecto.Changeset

  schema "polyjuice" do
    field :gas_limit, :integer
    field :gas_price, :decimal
    field :input, {:array, :binary}
    field :is_create, :boolean, default: false
    field :is_static, :boolean, default: false
    field :value, :decimal

    belongs_to(:transaction, GodwokenExplorer.Transaction, foreign_key: :tx_hash, references: :hash)

    timestamps()
  end

  @doc false
  def changeset(polyjuice, attrs) do
    polyjuice
    |> cast(attrs, [:tx_hash, :is_create, :is_static, :gas_limit, :gas_price, :value, :input])
    |> validate_required([:tx_hash, :is_create, :is_static, :gas_limit, :gas_price, :value, :input])
  end
end
