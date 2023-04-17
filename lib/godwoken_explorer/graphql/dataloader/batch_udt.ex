defmodule GodwokenExplorer.Graphql.Dataloader.BatchUDT do
  import Ecto.Query

  alias GodwokenExplorer.Account
  alias GodwokenExplorer.TokenInstance
  alias GodwokenExplorer.Repo

  def token_instance(TokenInstance, keys) do
    {key1s, key2s} = keys |> Enum.unzip()
    condition = dynamic([t], t.token_contract_address_hash in ^key1s and t.token_id in ^key2s)

    from(a in TokenInstance)
    |> where(
      [a],
      ^condition
    )
    |> Repo.all()
    |> Map.new(fn a ->
      {{a.token_contract_address_hash, a.token_id}, a}
    end)
  end

  def account(Account, ids) do
    from(a in Account)
    |> where(
      [a],
      a.id in ^ids
    )
    |> Repo.all()
    |> Map.new(fn a ->
      Account.async_fetch_transfer_and_transaction_count(a)
      {a.id, a}
    end)
  end

  def account_of_address(Account, addresses) do
    from(a in Account)
    |> where(
      [a],
      a.eth_address in ^addresses
    )
    |> Repo.all()
    |> Map.new(fn a ->
      Account.async_fetch_transfer_and_transaction_count(a)
      {a.eth_address, a}
    end)
  end
end
