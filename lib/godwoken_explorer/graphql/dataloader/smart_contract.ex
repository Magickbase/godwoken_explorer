defmodule GodwokenExplorer.Graphql.Dataloader.BatchSmartContract do
  import Ecto.Query

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Account
  alias GodwokenExplorer.Account.CurrentUDTBalance

  def account(Account, ids) do
    from(a in Account,
      where: a.id in ^ids
    )
    |> Repo.all()
    |> Map.new(fn a ->
      Account.async_fetch_transfer_and_transaction_count(a)
      {a.id, a}
    end)
  end

  def ckb_balance(CurrentUDTBalance, ids) do
    accounts =
      from(a in Account,
        where: a.id in ^ids
      )
      |> Repo.all()

    eth_addresses =
      accounts
      |> Enum.map(& &1.eth_address)

    accounts_id_address_map =
      accounts
      |> Enum.into(%{}, fn a -> {a.eth_address, a.id} end)

    CurrentUDTBalance.get_ckb_balance(eth_addresses)
    |> Enum.into(%{}, fn %{address: address, balance: balance} ->
      {Map.get(accounts_id_address_map, address), balance}
    end)
  end
end
