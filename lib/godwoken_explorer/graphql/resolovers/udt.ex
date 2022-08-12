defmodule GodwokenExplorer.Graphql.Resolvers.UDT do
  alias GodwokenExplorer.{UDT, Account}
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Account.CurrentBridgedUDTBalance

  import Ecto.Query

  import GodwokenExplorer.Graphql.Common,
    only: [cursor_order_sorter: 3]

  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]

  @sorter_fields [:name, :supply, :id]

  def holders_count(%UDT{} = udt, _args, _resolution) do
    {:ok, UDT.count_holder(udt)}
  end

  def udt(
        _parent,
        %{input: input},
        _resolution
      ) do
    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:contract_address, value} ->
            dynamic([u], ^acc and u.contract_address_hash == ^value)

          {:id, value} ->
            dynamic([u], ^acc and u.id == ^value)

          {:bridge_account_id, value} ->
            dynamic([u], ^acc and u.bridge_account_id == ^value)

          _ ->
            acc
        end
      end)

    query =
      from(u in UDT)
      |> where(^conditions)

    udt = Repo.one(query)
    mapping_udt = UDT.find_mapping_udt(udt)
    udt = merge_bridge_info_to_udt(udt, mapping_udt)
    {:ok, udt}
  end

  defp merge_bridge_info_to_udt(udt, mapping_udt) do
    if not is_nil(udt) do
      case udt.type do
        :native ->
          if not is_nil(mapping_udt) do
            Map.merge(udt, %{
              description: mapping_udt.description,
              official_site: mapping_udt.official_site
            })
          else
            udt
          end

        :bridge ->
          udt
      end
    else
      udt
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

  defp udts_where_fuzzy_name(query, input) do
    fuzzy_name = Map.get(input, :fuzzy_name)

    if fuzzy_name do
      query
      |> where([u], ilike(u.name, ^fuzzy_name))
    else
      query
    end
  end

  defp udts_order_by(query, input) do
    sorter = Map.get(input, :sorter)

    holders_query =
      from(cbub in CurrentBridgedUDTBalance)
      |> group_by([cbub], cbub.udt_id)
      # |> order_by([c], desc: count(c.id))
      |> select([c], %{id: c.udt_id, holders_count: count(c.id)})

    if sorter do
      holders_count =
        Enum.find(sorter, fn e ->
          case e do
            %{sort_type: _st, sort_value: :ex_holders_count} ->
              true

            _ ->
              false
          end
        end)

      if holders_count do
        query =
          query
          |> join(:inner, [u], h in subquery(holders_query), on: u.id == h.id, as: :holders)
          |> select_merge([_u, holders: h], %{holders_count: h.holders_count})

        order_params =
          sorter
          |> Enum.map(fn e ->
            case e do
              %{sort_type: st, sort_value: :ex_holders_count} ->
                # {st, :holders_count}

                {st, dynamic([_u, holders: h], h.holders_count)}

              _ ->
                case cursor_order_sorter([e], :order, @sorter_fields) do
                  [h | _] -> h
                  _ -> :skip
                end
            end
          end)
          |> Enum.filter(&(&1 != :skip))

        order_by(query, [], ^order_params)
      else
        order_params = cursor_order_sorter(sorter, :order, @sorter_fields)
        order_by(query, [], ^order_params)
      end
    else
      order_by(query, [u], [:id])
    end
  end

  defp paginate_cursor(input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      sorter
      |> Enum.map(fn e ->
        case e do
          %{sort_type: st, sort_value: :holders_count} ->
            {:holders_count, st}

          _ ->
            case cursor_order_sorter([e], :cursor, @sorter_fields) do
              [h | _] -> h
              _ -> :skip
            end
        end
      end)
      |> Enum.filter(&(&1 != :skip))
    else
      [:id]
    end
  end

  def account(%UDT{id: id} = _parent, _args, _resolution) do
    return =
      from(a in Account)
      |> where([a], a.id == ^id)
      |> Repo.one()

    {:ok, return}
  end
end
