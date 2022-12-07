defmodule GodwokenExplorer.Graphql.Dataloader.BatchLog do
  import Ecto.Query

  alias GodwokenExplorer.SmartContract
  alias GodwokenExplorer.Account
  alias GodwokenExplorer.Repo

  def smart_contract(SmartContract, address_hashes) do
    from(a in Account)
    |> where(
      [a],
      a.eth_address in ^address_hashes
    )
    |> join(:inner, [a], s in SmartContract, on: s.account_id == a.id)
    |> select([a, s], %{a: a, s: s})
    |> Repo.all()
    |> Map.new(fn %{a: a, s: s} ->
      {a.eth_address, s}
    end)
  end
end
