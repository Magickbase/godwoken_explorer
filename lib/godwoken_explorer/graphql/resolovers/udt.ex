defmodule GodwokenExplorer.Graphql.Resolvers.UDT do
  alias GodwokenExplorer.{UDT, Account}
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Account.{CurrentBridgedUDTBalance, CurrentUDTBalance}

  import Ecto.Query

  import GodwokenExplorer.Graphql.Common,
    only: [cursor_order_sorter: 3]

  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]

  @sorter_fields [:name, :supply, :id]

  def holders_count(%UDT{} = udt, _args, _resolution) do
    {:ok, UDT.count_holder(udt)}
  end

  def minted_count(%UDT{} = udt, _args, _resolution) do
    {:ok, UDT.minted_count(udt)}
  end

  def user_erc721_assets(_, %{input: input}, _) do
    user_address = Map.get(input, :user_address)
    contract_address = Map.get(input, :contract_address)

    from(cu in CurrentUDTBalance)
    |> where(
      [cu],
      cu.address_hash == ^user_address and cu.token_contract_address_hash == ^contract_address
    )
    |> order_by([c], desc: :block_number, desc: :value_fetched_at)
    |> paginate_query(input, %{
      cursor_fields: [block_number: :desc, value_fetched_at: :desc],
      total_count_primary_key_field: :id
    })
  end

  def erc721_udt(%UDT{contract_address_hash: contract_address_hash}, _, _) do
    return = Repo.get_by(UDT, contract_address_hash: contract_address_hash)
    {:ok, return}
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

          {:eth_type, value} ->
            dynamic([u], ^acc and u.eth_type == ^value)

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

  def erc721_udts(_parent, %{input: input} = _args, _resolution) do
    return =
      from(u in UDT)
      |> where([u], u.eth_type == :erc721)
      |> udts_where_fuzzy_name(input)
      |> erc721_udts_order_by(input)
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: :id
      })

    {:ok, return}
  end

  def erc721_holders(_parent, %{input: input} = _args, _resolution) do
    contract_address = Map.get(input, :contract_address)

    from(cu in CurrentUDTBalance)
    |> where([cu], cu.token_contract_address_hash == ^contract_address)
    |> group_by([cu], cu.address_hash)
    |> select([cu], %{
      address_hash: cu.address_hash,
      quantity: count(cu.token_id)
    })
    |> order_by([c], desc: :quantity, asc: :id)
    |> paginate_query(input, %{
      cursor_fields: [quantity: :desc, id: :asc],
      total_count_primary_key_field: [:address_hash, :token_contract_address_hash]
    })
  end

  defp udts_order_by(query, input) do
    sub_holders_count_query =
      from(cbub in CurrentBridgedUDTBalance)
      |> group_by([cbub], cbub.udt_id)
      |> select([c], %{id: c.udt_id, holders_count: count(c.id)})

    holders_count_query =
      query
      |> join(:left, [u], h in subquery(sub_holders_count_query),
        on: u.id == h.id,
        as: :holders_count
      )
      |> select_merge([_u, holders_count: h], %{holders_count: h.holders_count})

    base_udts_order_by(query, holders_count_query, input)
  end

  defp erc721_udts_order_by(query, input) do
    sub_holders_count_query =
      from(cu in CurrentUDTBalance)
      |> group_by([cu], cu.token_contract_address_hash)
      |> select([c], %{
        contract_address_hash: c.token_contract_address_hash,
        holders_count: count(c.token_contract_address_hash)
      })

    holders_count_query =
      query
      |> join(:left, [u], h in subquery(sub_holders_count_query),
        on: u.contract_address_hash == h.contract_address_hash,
        as: :holders_count
      )
      |> select_merge([_u, holders_count: h], %{holders_count: h.holders_count})

    base_udts_order_by(query, holders_count_query, input)
  end

  defp base_udts_order_by(query, holders_count_query, input) do
    sorter = Map.get(input, :sorter)

    holders_count_sorter_cond =
      Enum.find(sorter, fn e ->
        case e do
          %{sort_type: _st, sort_value: :ex_holders_count} ->
            true

          _ ->
            false
        end
      end)

    if sorter do
      if holders_count_sorter_cond do
        order_params =
          sorter
          |> Enum.map(fn e ->
            case e do
              %{sort_type: st, sort_value: :ex_holders_count} ->
                {st, dynamic([_u, holders_count: h], h.holders_count)}

              _ ->
                case cursor_order_sorter([e], :order, @sorter_fields) do
                  [h | _] -> h
                  _ -> :skip
                end
            end
          end)
          |> Enum.filter(&(&1 != :skip))

        order_by(holders_count_query, [], ^order_params)
      else
        order_params = cursor_order_sorter(sorter, :order, @sorter_fields)
        order_by(query, [], ^order_params)
      end
    else
      order_by(query, [u], [:id])
    end
  end
end
