defmodule GodwokenExplorer.Admin.SmartContract do
  use Ecto.Schema
  import Ecto.Changeset

  schema "smart_contracts" do
    field :abi, {:array, :map}
    field :account_id, :integer
    field :contract_source_code, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(smart_contract, attrs) do
    smart_contract
    |> cast(attrs, [:name, :contract_source_code, :abi, :account_id])
    |> validate_required([:name, :contract_source_code, :abi, :account_id])
  end
end
