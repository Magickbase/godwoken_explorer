defmodule GodwokenExplorer.Graphql.Resolvers.Account do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, SmartContract, AccountUDT}
  import Ecto.Query

  def account(_parent, %{input: input} = _args, _resolution) do
    {:ok, get_account_by_address(input)}
  end

  def account_udts(%Account{id: id}, _args, _resolution) do
    return =
      from(ac in AccountUDT, where: ac.account_id == ^id, limit: 100)
      |> Repo.all()

    {:ok, return}
  end

  def smart_contract(%Account{id: id}, _args, _resolution) do
    return =
      from(sm in SmartContract,
        where: sm.account_id == ^id
      )
      |> Repo.one()

    {:ok, return}
  end

  defp get_account_by_address(input) do
    eth_address_or_short_address = Map.get(input, :eth_address_or_short_address)

    Repo.one(
      from a in Account,
        where:
          a.eth_address == ^eth_address_or_short_address or
            a.short_address == ^eth_address_or_short_address or
            a.script_hash == ^eth_address_or_short_address
    )
  end
end
