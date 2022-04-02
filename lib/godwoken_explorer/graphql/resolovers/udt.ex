defmodule GodwokenExplorer.Graphql.Resolvers.UDT do
  alias GodwokenExplorer.{UDT, Account}
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2]

  def udt(_parent, %{input: input} = _args, _resolution) do
    id = Map.get(input, :id)
    udt = Repo.get(UDT, id)
    {:ok, udt}
  end

  def get_udt_by_contract_address(
        _parent,
        %{input: %{contract_address: contract_address}},
        _resolution
      ) do
    account = Account.search(contract_address)

    udt =
      from(u in UDT)
      |> where([u], u.id == ^account.id or u.bridge_account_id == ^account.id)
      |> Repo.one()

    {:ok, udt}
  end

  def udts(_parent, %{input: input} = _args, _resolution) do
    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:type, value} ->
            dynamic([u], ^acc and u.type == ^value)

          _ ->
            acc
        end
      end)

    return = conditions |> page_and_size(input) |> Repo.all()

    {:ok, return}
  end

  def account(%UDT{bridge_account_id: bridge_account_id} = _parent, _args, _resolution) do
    account = Repo.get(Account, bridge_account_id)
    {:ok, account}
  end
end
