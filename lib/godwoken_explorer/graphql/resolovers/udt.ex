defmodule GodwokenExplorer.Graphql.Resolvers.UDT do
  alias GodwokenExplorer.{UDT, Account}
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]

  def udt(
        _parent,
        %{input: %{contract_address: contract_address}},
        _resolution
      ) do
    account = Account.search(contract_address)

    if account do
      udt =
        from(u in UDT)
        |> where([u], u.id == ^account.id or u.bridge_account_id == ^account.id)
        |> Repo.one()

      {:ok, udt}
    else
      {:ok, nil}
    end
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

    return =
      from(u in UDT)
      |> where(^conditions)
      |> page_and_size(input)
      |> sort_type(input, :inserted_at)
      |> Repo.all()

    {:ok, return}
  end

  def account(%UDT{id: id} = _parent, _args, _resolution) do
    return =
      from(a in Account)
      |> where([a], a.id == ^id)
      |> Repo.one()

    {:ok, return}
  end
end
