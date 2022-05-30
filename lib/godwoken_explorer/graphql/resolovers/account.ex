defmodule GodwokenExplorer.Graphql.Resolvers.Account do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, SmartContract, AccountUDT, UDT}

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]

  def account(_parent, %{input: input} = _args, _resolution) do
    address = Map.get(input, :address)
    return = Account.search(address)
    Account.async_fetch_transfer_and_transaction_count(return)

    {:ok, return}
  end

  def account_udts(%Account{id: id}, %{input: input} = _args, _resolution) do
    account_ckb_id = UDT.ckb_account_id()

    return =
      from(ac in AccountUDT)
      |> where([ac], ac.account_id == ^id)
      |> order_by([ac], desc: ac.updated_at)
      |> distinct([ac], ac.token_contract_address_hash)
      |> page_and_size(input)
      |> sort_type(input, :balance)
      |> Repo.all()
      |> Enum.filter(fn r -> r.udt_id != account_ckb_id end)

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
