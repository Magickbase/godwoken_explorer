defmodule GodwokenExplorer.Graphql.Resolvers.SmartContract do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{SmartContract, Account}

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]

  def smart_contract(
        _parent,
        %{input: input} = _args,
        _resolution
      ) do
    contract_address = Map.get(input, :contract_address)
    script_hash = Map.get(input, :script_hash)

    account =
      case {contract_address, script_hash} do
        {nil, script_hash} when not is_nil(script_hash) ->
          Account.search(script_hash)

        {contract_address, _} when not is_nil(contract_address) ->
          Account.search(contract_address)

        {nil, nil} ->
          nil
      end

    if account do
      return =
        from(sc in SmartContract)
        |> where([sc], sc.account_id == ^account.id)
        |> Repo.one()

      {:ok, return}
    else
      {:ok, nil}
    end
  end

  def smart_contracts(_parent, %{input: input} = _args, _resolution) do
    return =
      from(sc in SmartContract)
      |> page_and_size(input)
      |> sort_type(input, :inserted_at)
      |> Repo.all()

    {:ok, return}
  end

  def account(%SmartContract{account_id: account_id} = _parent, _args, _resolution) do
    if account_id do
      return = Repo.get(Account, account_id)

      {:ok, return}
    else
      {:ok, nil}
    end
  end
end
