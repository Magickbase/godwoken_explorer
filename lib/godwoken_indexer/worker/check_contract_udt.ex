defmodule GodwokenIndexer.Worker.CheckContractUDT do
  @moduledoc """
  Check contract is a token and import to `GodwokenExplorer.UDT`.

  """
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Account, Repo, SmartContract, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever
  alias GodwokenIndexer.Worker.CheckContractUDT

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"address" => address}}) do
    do_perform(address)
    :ok
  end

  def do_perform(address) do
    check_is_erc721(address)
    check_is_erc1155(address)
    check_is_erc20(address)
  end

  def recheck_contract_udt(type) when type in [:erc1155, :erc721] do
    q =
      case type do
        :erc721 ->
          from(u in UDT, where: u.eth_type == :erc721)

        :erc1155 ->
          from(u in UDT, where: u.eth_type == :erc721)
      end

    st = Repo.stream(q)

    Repo.transaction(fn ->
      Enum.each(st, fn u ->
        address = u.contract_address_hash |> to_string()

        %{address: address}
        |> CheckContractUDT.new()
        |> Oban.insert()
      end)
    end)
  end

  defp check_is_erc1155(address) do
    with true <- UDT.is_erc1155?(address),
         %Account{id: id, contract_code: contract_code} <-
           Repo.get_by(Account, eth_address: address),
         nil <- Repo.get(UDT, id) do
      %UDT{}
      |> UDT.changeset(%{
        id: id,
        type: :native,
        eth_type: :erc1155,
        contract_address_hash: address
      })
      |> Repo.insert()

      if contract_code != nil, do: import_exist_smart_contract(contract_code, id)
    end
  end

  defp check_is_erc20(address) do
    with %{name: name, symbol: symbol, supply: supply, decimal: decimal} <-
           MetadataRetriever.get_functions_of(address),
         %Account{id: id, contract_code: contract_code} <-
           Repo.get_by(Account, eth_address: address),
         nil <- Repo.get(UDT, id) do
      %UDT{}
      |> UDT.changeset(%{
        id: id,
        type: :native,
        eth_type: :erc20,
        contract_address_hash: address,
        name: name,
        symbol: symbol,
        supply: supply,
        decimal: decimal
      })
      |> Repo.insert()

      if contract_code != nil, do: import_exist_smart_contract(contract_code, id)
    end
  end

  defp check_is_erc721(address) do
    with true <- UDT.is_erc721?(address),
         %Account{id: id, contract_code: contract_code} <-
           Repo.get_by(Account, eth_address: address),
         nil <- Repo.get(UDT, id) do
      %UDT{}
      |> UDT.changeset(%{
        id: id,
        type: :native,
        eth_type: :erc721,
        contract_address_hash: address
      })
      |> Repo.insert()

      if contract_code != nil, do: import_exist_smart_contract(contract_code, id)
    end
  end

  defp import_exist_smart_contract(contract_code, id) do
    sc =
      from(a in Account,
        join: sc in SmartContract,
        on: sc.account_id == a.id,
        where: a.contract_code == ^contract_code and a.id != ^id and not is_nil(sc.abi),
        select: sc,
        limit: 1
      )
      |> Repo.one()

    if sc != nil do
      Repo.insert(
        %SmartContract{
          name: sc.name,
          account_id: id,
          abi: sc.abi,
          contract_source_code: sc.contract_source_code,
          compiler_version: sc.compiler_version
        },
        on_conflict: {:replace, [:name, :abi, :contract_source_code, :compiler_version]},
        conflict_target: :account_id
      )
    end
  end
end
