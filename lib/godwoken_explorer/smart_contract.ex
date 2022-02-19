defmodule GodwokenExplorer.SmartContract do
  use GodwokenExplorer, :schema

  schema "smart_contracts" do
    field(:abi, {:array, :map})
    field :contract_source_code, :string
    field :name, :string

    belongs_to(
      :account,
      Account,
      foreign_key: :account_id,
      references: :id,
      type: :integer
    )

    timestamps()
  end

  @doc false
  def changeset(smart_contract, attrs) do
    smart_contract
    |> cast(attrs, [:name, :contract_source_code, :abi, :account_id])
    |> validate_required([:name, :contract_source_code, :abi, :account_id])
  end

  def reformat_abi(abi) do
    abi
    |> Enum.map(&map_abi/1)
    |> Map.new()
  end

  def account_ids do
    if FastGlobal.get(:contract_account_ids) do
      FastGlobal.get(:contract_account_ids)
    else
     account_ids = SmartContract |> select([sc], sc.account_id) |> Repo.all()
     FastGlobal.put(:contract_account_ids, account_ids)
     account_ids
    end
  end

  defp map_abi(x) do
    case {x["name"], x["type"]} do
      {nil, "constructor"} -> {:constructor, x}
      {nil, "fallback"} -> {:fallback, x}
      {name, _} -> {name, x}
    end
  end
end
