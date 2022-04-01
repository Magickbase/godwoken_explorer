defmodule GodwokenExplorer.Graphql.Resolvers.SmartContract do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{SmartContract, Account}

  import Ecto.Query
  import GodwokenExplorer.Graphql.PageAndSize, only: [page_and_size: 2]

  def smart_contract(
        _parent,
        %{input: %{contract_address: contract_address}} = _args,
        _resolution
      ) do
    account = Account.search(contract_address)

    return =
      from(sc in SmartContract)
      |> where([sc], sc.account_id == ^account.id)
      |> Repo.one()

    {:ok, return}
  end

  def smart_contracts(_parent, %{input: input} = _args, _resolution) do
    return =
      from(sc in SmartContract)
      |> page_and_size(input)
      |> Repo.all()

    {:ok, return}
  end
end
