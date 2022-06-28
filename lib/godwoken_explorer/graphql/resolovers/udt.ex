defmodule GodwokenExplorer.Graphql.Resolvers.UDT do
  alias GodwokenExplorer.{UDT, Account}
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import Ecto.Query.API, only: [ilike: 2, like: 2]
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]
  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]

  def udt(
        _parent,
        %{input: input},
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
      udt =
        from(u in UDT)
        |> where([u], u.id == ^account.id or u.bridge_account_id == ^account.id)
        |> Repo.one()

      {:ok, udt}
    else
      {:ok, nil}
    end
  end

  def get_udt_by_account_id(
        _parent,
        %{input: %{account_id: account_id}},
        _resolution
      ) do
    udt =
      from(u in UDT)
      |> where([u], u.id == ^account_id or u.bridge_account_id == ^account_id)
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

    return =
      from(u in UDT)
      |> where(^conditions)
      |> udts_where_fuzzy_name(input)
      |> udts_order_by(input)
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: :id
      })

    {:ok, return}
  end

  def udts_where_fuzzy_name(query, input) do
    fuzzy_name = Map.get(input, :fuzzy_name)

    if fuzzy_name do
      query
      |> where([u], ilike(u.name, ^fuzzy_name))
    else
      query
    end
  end

  def udts_order_by(query, input) do
    sorter = Map.get(input, :sorter) |> IO.inspect()

    if sorter do
      order_params = udts_sorter(sorter, :order) |> IO.inspect()
      order_by(query, [u], ^order_params)
    else
      order_by(query, [u], [:id])
    end
  end

  def paginate_cursor(input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      udts_sorter(sorter, :cursor)
    else
      [:id]
    end
  end

  defp udts_sorter(sorter, type) when type in [:order, :cursor] do
    sorter
    |> Enum.map(fn %{sort_type: st, sort_value: sv} ->
      case sv do
        :name ->
          if type == :order do
            {st, :name}
          else
            {:name, st}
          end

        :supply ->
          if type == :order do
            {st, :supply}
          else
            {:supply, st}
          end

        :id ->
          if type == :order do
            {st, :id}
          else
            {:id, st}
          end

        _ ->
          :todo
      end
    end)
    |> Enum.filter(&(&1 != :todo))
  end

  def account(%UDT{id: id} = _parent, _args, _resolution) do
    return =
      from(a in Account)
      |> where([a], a.id == ^id)
      |> Repo.one()

    {:ok, return}
  end
end
