defmodule GodwokenExplorer.Graphql.Resolvers.Account do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, SmartContract, UDT}
  alias GodwokenExplorer.Account.{CurrentUDTBalance, CurrentBridgedUDTBalance}

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]

  def account(_parent, %{input: input} = _args, _resolution) do
    address = Map.get(input, :address)
    script_hash = Map.get(input, :script_hash)

    case {address, script_hash} do
      {nil, nil} ->
        {:error, "address or script_hash is required"}

      {nil, _} ->
        return = Account.search(script_hash)
        Account.async_fetch_transfer_and_transaction_count(return)
        {:ok, return}

      {_, _} ->
        return = Account.search(address)
        Account.async_fetch_transfer_and_transaction_count(return)
        {:ok, return}
    end
  end

  def udt(%Account{id: id}, _args, _resolution) do
    udt =
      from(u in UDT)
      |> where([u], u.id == ^id or u.bridge_account_id == ^id)
      |> Repo.one()

    {:ok, udt}
  end

  def account_current_udts(%Account{eth_address: eth_address}, %{input: input} = _args, _resolution) do

    return =
      from(cu in CurrentUDTBalance)
      |> where([cu], cu.address_hash == ^eth_address)
      |> order_by([cu], desc: cu.updated_at)
      |> distinct([cu], cu.token_contract_address_hash)
      |> page_and_size(input)
      |> sort_type(input, :value)
      |> Repo.all()

    {:ok, return}
  end

  def account_current_bridged_udts(%Account{eth_address: eth_address}, %{input: input} = _args, _resolution) do

    return =
      from(cbu in CurrentBridgedUDTBalance)
      |> where([cbu], cbu.address_hash == ^eth_address)
      |> order_by([cbu], desc: cbu.updated_at)
      |> distinct([cbu], cbu.udt_script_hash)
      |> page_and_size(input)
      |> sort_type(input, :value)
      |> Repo.all()

    {:ok, return}
  end

  def smart_contract(%Account{id: id}, _args, _resolution) do
    return =
      from(sm in SmartContract)
      |> where([sm], sm.account_id == ^id)
      |> Repo.one()

    {:ok, return}
  end
end
