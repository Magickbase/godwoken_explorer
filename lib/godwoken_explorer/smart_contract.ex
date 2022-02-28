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

    field :constructor_arguments, :binary
    field :deployment_tx_hash, :binary
    field :compiler_version, :string
    field :compiler_file_format, :string
    field :other_info, :string

    timestamps()
  end

  defp base_fields() do
    GodwokenExplorer.SchemeUtils.base_fields_without_id(__MODULE__)
  end

  @doc false
  def changeset(smart_contract, attrs) do
    smart_contract
    |> cast(attrs, base_fields())
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

  def cache_abi(account_id) do
    if FastGlobal.get("contract_abi_#{account_id}") do
      FastGlobal.get("contract_abi_#{account_id}")
    else
      abi =
        from(sc in SmartContract, where: sc.account_id == ^account_id, select: sc.abi)
        |> Repo.one()

      FastGlobal.put("contract_abi_#{account_id}", abi)
      abi
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
