defmodule GodwokenExplorer.Polyjuice do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  schema "polyjuice" do
    field :is_create, :boolean, default: false
    field :is_static, :boolean, default: false
    field :gas_limit, :integer
    field :gas_price, :decimal
    field :value, :decimal
    field :input_size, :integer
    field :input, :binary
    field :tx_hash, :binary

    belongs_to(:transaction, GodwokenExplorer.Transaction, foreign_key: :tx_hash, references: :hash, define_field: false)

    timestamps()
  end

  @doc false
  def changeset(polyjuice, attrs) do
    polyjuice
    |> cast(attrs, [:is_create, :is_static, :gas_limit, :gas_price, :value, :input_size, :input])
    |> validate_required([:is_create, :is_static, :gas_limit, :gas_price, :value, :input_size, :input])
  end

  def create_polyjuice(attrs) do
    %Polyjuice{}
    |> Polyjuice.changeset(attrs)
    |> Ecto.Changeset.put_change(:tx_hash, attrs[:hash])
    |> Repo.insert()
  end

end
