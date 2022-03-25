defmodule GodwokenExplorer.Graphql.Resolvers.SmartContract do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{SmartContract, Account}

  import Ecto.Query

  def smart_contract(
        _parent,
        %{input: %{contract_address: contract_address}} = _args,
        _resolution
      ) do
    account = Account.search(contract_address)
    return = from(sc in SmartContract, where: sc.account_id == ^account.id) |> Repo.one()
    {:ok, return}
  end

  # TODO: wait for optimize
  def smart_contracts(_parent, _args, _resolution) do
    return = Repo.all(SmartContract)
    {:ok, return}
  end
end
