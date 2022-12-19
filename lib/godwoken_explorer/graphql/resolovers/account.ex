defmodule GodwokenExplorer.Graphql.Resolvers.Account do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, SmartContract, UDT}
  alias GodwokenExplorer.Account.{CurrentUDTBalance, CurrentBridgedUDTBalance}
  alias GodwokenExplorer.Graphql.Dataloader.BatchAccount

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  def account(_parent, %{input: input} = _args, _resolution) do
    address = Map.get(input, :address)
    script_hash = Map.get(input, :script_hash)

    case {address, script_hash} do
      {nil, nil} ->
        {:error, "address or script_hash is required"}

      {nil, _} ->
        return = Repo.get_by(Account, script_hash: script_hash)

        Account.async_fetch_transfer_and_transaction_count(return)

        {:ok, return}

      {_, _} ->
        return = Repo.get_by(Account, eth_address: address)
        Account.async_fetch_transfer_and_transaction_count(return)
        {:ok, return}
    end
  end

  def udt(%Account{id: id}, _args, _resolution) do
    batch({BatchAccount, :udt, UDT}, id, fn batch_results ->
      {:ok, Map.get(batch_results, id)}
    end)
  end

  def bridged_udt(%Account{id: id}, _args, _resolution) do
    batch({BatchAccount, :bridge_udt, UDT}, id, fn batch_results ->
      {:ok, Map.get(batch_results, id)}
    end)
  end

  def smart_contract(%Account{id: id}, _args, _resolution) do
    return =
      from(sm in SmartContract)
      |> where([sm], sm.account_id == ^id)
      |> Repo.one()

    {:ok, return}
  end
end
