defmodule GodwokenExplorer.Graphql.Resolvers.Address do
  alias GodwokenExplorer.{Address, Repo, UDT}
  alias GodwokenExplorer.Account.CurrentUDTBalance

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]

  def address(_parent, %{input: input} = _args, _resolution) do
    address = Map.get(input, :address)

    case Repo.get(Address, address) do
      %Address{} = address ->
        Address.async_update_info(address)
        {:ok, address}

      nil ->
        {:ok, nil}
    end
  end

  def address_current_udts(
        %Address{eth_address: eth_address},
        %{input: input} = _args,
        _resolution
      ) do
    return =
      from(cu in CurrentUDTBalance)
      |> where([cu], cu.address_hash == ^eth_address and cu.token_type == :erc20)
      |> order_by([cu], desc: cu.updated_at)
      |> join(:inner, [cu], a in Account, on: a.eth_address == cu.token_contract_address_hash)
      |> join(:inner, [cu, a], u in UDT, on: a.id == u.bridge_account_id)
      |> page_and_size(input)
      |> sort_type(input, :value)
      |> Repo.all()

    {:ok, return}
  end
end
