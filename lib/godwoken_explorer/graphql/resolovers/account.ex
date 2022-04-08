defmodule GodwokenExplorer.Graphql.Resolvers.Account do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, SmartContract, AccountUDT}
  import Ecto.Query

  def account(_parent, %{input: input} = _args, _resolution) do
    address = Map.get(input, :address)

    return =
      from(a in Account)
      |> where(
        [a],
        a.eth_address == ^address or
          a.short_address == ^address or
          a.script_hash == ^address
      )
      |> Repo.one()

    {:ok, return}
  end

  def account_udts(%Account{id: id}, _args, _resolution) do
    return =
      from(ac in AccountUDT)
      |> where([ac], ac.account_id == ^id)
      |> order_by(desc: :balance)
      |> limit(20)
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
