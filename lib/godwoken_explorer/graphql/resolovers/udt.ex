defmodule GodwokenExplorer.Graphql.Resolvers.UDT do
  alias GodwokenExplorer.{UDT, Account}
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Account.{CurrentBridgedUDTBalance, CurrentUDTBalance, UDTBalance}
  alias GodwokenExplorer.TokenTransfer
  alias GodwokenExplorer.TokenInstance
  alias GodwokenExplorer.Chain.Cache.TokenExchangeRate, as: CacheTokenExchangeRate
  alias GodwokenExplorer.Graphql.Dataloader.BatchUDT
  import Ecto.Query
  # import Ecto.Query.API, only: [fragment: 1]

  import GodwokenExplorer.Graphql.Common,
    only: [cursor_order_sorter: 3]

  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]
  import Absinthe.Resolution.Helpers

  @sorter_fields [:name, :supply, :id]

  def token_instance(
        %{token_contract_address_hash: token_contract_address_hash, token_id: token_id},
        _args,
        _resolution
      ) do
    get_token_instance({token_contract_address_hash, token_id})
  end

  def erc1155_inventory_token_instance(
        %{contract_address_hash: contract_address_hash, token_id: token_id},
        _args,
        _resolution
      ) do
    get_token_instance({contract_address_hash, token_id})
  end

  defp get_token_instance({contract_address, token_id} = compose_key) do
    batch(
      {BatchUDT, :token_instance, TokenInstance},
      {contract_address, token_id},
      fn batch_results ->
        {:ok, Map.get(batch_results, compose_key)}
      end
    )

    # Repo.get_by(TokenInstance,
    #   token_contract_address_hash: contract_address,
    #   token_id: token_id
    # )
  end

  def alias_counts(%{value: value}, _args, _resolution) do
    {:ok, value}
  end

  def holders_count(%{id: id}, _args, _resolution) do
    udt = Repo.get(UDT, id)
    {:ok, UDT.count_holder(udt)}
  end

  def minted_count(
        %{contract_address_hash: _contract_address_hash} = udt,
        _args,
        _resolution
      ) do
    return = UDT.minted_count(udt) |> Decimal.new()
    {:ok, return}
  end

  def token_exchange_rate(%UDT{} = udt, _args, _resolution) do
    symbol = udt.symbol
    uan = udt.uan

    if not is_nil(symbol) and not is_nil(uan) and udt.is_fetch_exchange_rate do
      fetch_symbol = hd(String.split(symbol, "."))

      fetch_symbol =
        if fetch_symbol == "pCKB" do
          "CKB"
        else
          fetch_symbol
        end

      {exchange_rate, timestamp} = CacheTokenExchangeRate.sync_fetch_by_symbol(fetch_symbol)

      exchange_rate =
        if exchange_rate == 0 do
          Decimal.new(0)
        else
          exchange_rate
        end

      {:ok, %{symbol: symbol, exchange_rate: exchange_rate, timestamp: timestamp}}
    else
      {:ok, nil}
    end
  end

  def erc1155_minted_count(
        %{contract_address_hash: contract_address_hash} = _udt,
        _args,
        _resolution
      ) do
    query =
      from(cu in CurrentUDTBalance,
        where: cu.token_contract_address_hash == ^contract_address_hash,
        select: sum(cu.value)
      )

    return = Repo.one(query)
    {:ok, return}
  end

  def erc1155_user_token(_, %{input: input}, _) do
    user_address = Map.get(input, :user_address)
    contract_address = Map.get(input, :contract_address)
    token_id = Map.get(input, :token_id)

    query =
      from(cu in CurrentUDTBalance)
      |> where(
        [cu],
        cu.address_hash == ^user_address and cu.token_contract_address_hash == ^contract_address and
          cu.token_id == ^token_id
      )

    {:ok, Repo.one(query)}
  end

  def user_erc721_assets(_, %{input: input}, _) do
    return = do_user_erc721_erc1155_assets(input, :erc721)

    {:ok, return}
  end

  def user_erc1155_assets(_, %{input: input}, _) do
    return = do_user_erc721_erc1155_assets(input, :erc1155)

    {:ok, return}
  end

  defp do_user_erc721_erc1155_assets(input, type) do
    user_address = Map.get(input, :user_address)

    base_conditions =
      case type do
        :erc721 -> dynamic([cu], cu.token_type == :erc721)
        :erc1155 -> dynamic([cu], cu.token_type == :erc1155)
      end

    from(cu in CurrentUDTBalance)
    |> where([cu], ^base_conditions)
    |> where([cu], cu.value > 0)
    |> where(
      [cu],
      cu.address_hash == ^user_address
    )
    |> order_by([c], desc: :block_number, desc: :updated_at, desc: :id)
    |> paginate_query(input, %{
      cursor_fields: [block_number: :desc, updated_at: :desc, id: :desc],
      total_count_primary_key_field: :id
    })
  end

  def erc721_erc1155_udt(
        parent = %CurrentUDTBalance{},
        _,
        %{context: %{loader: loader}}
      ) do
    loader
    |> Dataloader.load(:graphql, :udt_of_address, parent)
    |> on_load(fn loader ->
      udt =
        loader
        |> Dataloader.get(:graphql, :udt_of_address, parent)

      {:ok, udt}
    end)
  end

  def udt(
        _parent,
        %{input: input},
        _resolution
      ) do
    with false <- %{} == input or is_nil(input) do
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
      hc = UDT.count_holder(udt)

      udt =
        if udt do
          if udt.contract_address_hash,
            do: UDT.async_fetch_total_supply(udt.contract_address_hash)

          udt |> Map.put(:holders_count, hc)
        else
          nil
        end

      {:ok, udt}
    else
      _ ->
        {:ok, nil}
    end
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

          {:contract_address, value} ->
            dynamic([u], ^acc and u.contract_address_hash == ^value)

          _ ->
            acc
        end
      end)

    return =
      from(u in UDT)
      |> where([u], u.type == :bridge or (u.type == :native and u.eth_type == :erc20))
      |> where(^conditions)
      |> udts_where_fuzzy_name(input)
      |> udts_order_by(input)
      |> udts_rank()
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: :id
      })

    {:ok, return}
  end

  defp udts_rank(query) do
    from(u in UDT,
      right_join: uh in subquery(query),
      as: :u_holders,
      on: u.id == uh.id,
      select: merge(uh, %{rank: row_number() |> over()})
    )
  end

  defp udts_order_by(query, input) do
    s2 =
      from(c in CurrentUDTBalance,
        where: c.value > 0 and c.token_type == :erc20,
        join: u in UDT,
        on: u.contract_address_hash == c.token_contract_address_hash,
        select: %{udt_id: u.id, address_hash: c.address_hash}
      )

    s1 =
      from(cb in CurrentBridgedUDTBalance,
        where: cb.value > 0,
        join: u in UDT,
        on: u.id == cb.udt_id,
        select: %{udt_id: u.bridge_account_id, address_hash: cb.address_hash}
      )

    s =
      from(s in subquery(union(s2, ^s1)))
      |> group_by([c], c.udt_id)
      |> select([c], %{
        udt_id: c.udt_id,
        holders_count: count(c.address_hash, :distinct)
      })

    s2 =
      query
      |> join(:left, [u], h in subquery(s),
        on:
          (u.id == h.udt_id and is_nil(u.bridge_account_id)) or
            u.bridge_account_id == h.udt_id
      )
      |> select_merge([u, u_holders], %{
        holders_count:
          fragment(
            "CASE WHEN ? IS NULL THEN 0 ELSE ? END",
            u_holders.holders_count,
            u_holders.holders_count
          )
      })

    holders_count_query =
      query
      |> join(:inner, [u], uh in subquery(s2), on: u.id == uh.id, as: :u_holders)
      |> select(
        [u, uh],
        uh
      )

    base_udts_order_by(holders_count_query, input)
  end

  defp udts_where_fuzzy_name(query, input) do
    fuzzy_name = Map.get(input, :fuzzy_name)

    if fuzzy_name do
      query
      |> where([u], ilike(u.name, ^fuzzy_name) or ilike(u.display_name, ^fuzzy_name))
    else
      query
    end
  end

  defp paginate_cursor(input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      return =
        Enum.map(sorter, fn e ->
          case e do
            %{sort_type: st, sort_value: :ex_holders_count} ->
              {{:u_holders, :holders_count}, st}

            %{sort_type: st, sort_value: :minted_count} ->
              {{:u_holders, :minted_count}, st}

            %{sort_type: st, sort_value: :token_type_count} ->
              {{:u_holders, :token_type_count}, st}

            _ ->
              cursor_order_sorter(e, :cursor, @sorter_fields)
          end
        end)

      if List.keyfind(return, :id, 0) do
        return
      else
        return ++ [{:id, :asc}]
      end
    else
      [{:id, :asc}]
    end
  end

  def account(%UDT{id: id} = _parent, _args, _resolution) do
    batch({BatchUDT, :account, Account}, id, fn batch_results ->
      {:ok, Map.get(batch_results, id)}
    end)
  end

  def account_of_address(%{address_hash: address_hash} = _parent, _args, _resolution) do
    batch({BatchUDT, :account_of_address, Account}, address_hash, fn batch_results ->
      {:ok, Map.get(batch_results, address_hash)}
    end)
  end

  def erc721_udts(_parent, %{input: input} = _args, _resolution) do
    return =
      from(u in UDT)
      |> udts_condition_with_type(:erc721)
      |> udts_condition_query(input)
      |> udts_where_fuzzy_name(input)
      |> erc721_erc1155_udts_order_by(input, :erc721)
      |> udts_rank()
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: :id
      })

    {:ok, return}
  end

  def erc1155_udts(_parent, %{input: input} = _args, _resolution) do
    return =
      from(u in UDT)
      |> udts_condition_with_type(:erc1155)
      |> udts_condition_query(input)
      |> udts_where_fuzzy_name(input)
      |> erc721_erc1155_udts_order_by(input, :erc1155)
      |> udts_rank()
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: :id
      })

    {:ok, return}
  end

  defp udts_condition_with_type(query, type) when type in [:erc20, :erc721, :erc1155] do
    query |> where([u], u.eth_type == ^type)
  end

  defp udts_condition_query(query, input) do
    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:contract_address, value} ->
            dynamic([u], ^acc and u.contract_address_hash == ^value)

          _ ->
            acc
        end
      end)

    query
    |> where([u], ^conditions)
  end

  defp erc721_erc1155_udts_order_by(query, input, type) do
    minted_burn_address_hash = UDTBalance.minted_burn_address_hash()

    squery =
      from(
        cu in CurrentUDTBalance,
        where: cu.value > 0
      )
      |> where([cu], cu.address_hash != ^minted_burn_address_hash)
      |> group_by([cu], cu.token_contract_address_hash)
      |> select([cu], %{
        contract_address_hash: cu.token_contract_address_hash,
        holders_count: count(cu.address_hash, :distinct)
      })

    ## erc1155 need token_type_count
    s1 =
      from(cu in CurrentUDTBalance)
      |> where([cu], cu.token_type == :erc1155)
      |> where([cu], cu.address_hash != ^minted_burn_address_hash)
      |> group_by([cu], cu.token_contract_address_hash)
      |> select([cu], %{
        contract_address_hash: cu.token_contract_address_hash,
        token_type_count: count(cu.token_id, :distinct)
      })

    s2 =
      if type == :erc1155 do
        query
        |> join(:left, [u], h in subquery(squery),
          on: u.contract_address_hash == h.contract_address_hash
        )
        |> join(:left, [u], ttc in subquery(s1),
          on: u.contract_address_hash == ttc.contract_address_hash
        )
        |> select_merge([u, u_holders, u_type_counts], %{
          holders_count:
            fragment(
              "CASE WHEN ? IS NULL THEN 0 ELSE ? END",
              u_holders.holders_count,
              u_holders.holders_count
            ),
          token_type_count:
            fragment(
              "CASE WHEN ? IS NULL THEN 0 ELSE ? END",
              u_type_counts.token_type_count,
              u_type_counts.token_type_count
            )
        })
      else
        # erc721 need minted_count for sorting
        query
        |> join(:left, [u], h in subquery(squery),
          on: u.contract_address_hash == h.contract_address_hash
        )
        |> select_merge([u, u_holders], %{
          holders_count:
            fragment(
              "CASE WHEN ? IS NULL THEN 0 ELSE ? END",
              u_holders.holders_count,
              u_holders.holders_count
            ),
          minted_count:
            fragment(
              "CASE WHEN ? IS NULL THEN 0
              WHEN ? IS NULL THEN ?
              ELSE ? END",
              u.created_count,
              u.burnt_count,
              u.created_count,
              u.created_count - u.burnt_count
            )
        })
      end

    holders_count_query =
      query
      |> join(:inner, [u], uh in subquery(s2), on: u.id == uh.id, as: :u_holders)
      |> select([u, u_holders], u_holders)

    base_udts_order_by(holders_count_query, input)
  end

  def erc721_holders(_parent, %{input: input} = _args, _resolution) do
    contract_address = Map.get(input, :contract_address)

    squery =
      from(cu in CurrentUDTBalance)
      |> where(
        [cu],
        cu.token_contract_address_hash == ^contract_address and cu.token_type == :erc721 and
          cu.value > 0 and not is_nil(cu.token_id)
      )
      |> order_by([cu],
        desc: cu.block_number,
        desc: cu.id
      )
      |> distinct([cu], [cu.address_hash, cu.token_id])
      |> select([cu], %{
        id: cu.id,
        address_hash: cu.address_hash,
        token_contract_address_hash: cu.token_contract_address_hash,
        token_id: cu.token_id
      })

    sq2 =
      from(c in CurrentUDTBalance)
      |> join(:inner, [c], cu in subquery(squery), on: c.id == cu.id)
      |> group_by([c, cu], [cu.address_hash, cu.token_contract_address_hash])
      |> order_by([c, cu], desc: type(count(cu.token_id), :decimal), desc: cu.address_hash)
      |> select([c, cu], %{
        address_hash: cu.address_hash,
        token_contract_address_hash: cu.token_contract_address_hash,
        quantity: type(count(cu.token_id), :decimal)
      })

    sq3 =
      from(a in Account)
      |> join(:right, [a], cu in subquery(sq2), on: a.eth_address == cu.address_hash)
      |> select(
        [_, cu],
        merge(cu, %{
          rank:
            row_number()
            |> over(
              partition_by: cu.token_contract_address_hash,
              order_by: [desc: cu.quantity, desc: cu.address_hash]
            )
        })
      )

    return =
      from(a in Account)
      |> join(:right, [c], cu in subquery(sq3), on: c.eth_address == cu.address_hash, as: :holders)
      |> select([c, holders], holders)
      |> paginate_query(input, %{
        cursor_fields: [{{:holders, :quantity}, :desc}, {{:holders, :address_hash}, :desc}],
        total_count_primary_key_field: [:address_hash]
      })

    {:ok, return}
  end

  def erc1155_holders(_parent, %{input: input} = _args, _resolution) do
    contract_address = Map.get(input, :contract_address)
    token_id = Map.get(input, :token_id)

    token_id_cond =
      if token_id do
        dynamic([c], c.token_id == ^token_id)
      else
        true
      end

    query =
      from(cu in CurrentUDTBalance, as: :cub)
      |> where(
        [cu],
        cu.token_contract_address_hash == ^contract_address and cu.token_type == :erc1155 and
          cu.value > 0
      )
      |> where([_cu], ^token_id_cond)
      |> group_by([cu], [
        cu.address_hash,
        cu.token_contract_address_hash
      ])
      |> select([cu], %{
        address_hash: cu.address_hash,
        token_contract_address_hash: cu.token_contract_address_hash,
        quantity: sum(cu.value),
        rank:
          row_number()
          |> over(
            partition_by: :token_contract_address_hash,
            order_by: [desc: sum(cu.value), asc: cu.address_hash]
          )
      })

    return =
      from(u in UDT,
        right_join: cu in subquery(query),
        as: :holders,
        on: u.contract_address_hash == cu.token_contract_address_hash,
        select: cu
      )
      |> paginate_query(input, %{
        cursor_fields: [{{:holders, :quantity}, :desc}, {{:holders, :address_hash}, :asc}],
        total_count_primary_key_field: [:address_hash, :token_contract_address_hash]
      })

    {:ok, return}
  end

  def erc721_inventory(_, %{input: input} = _args, _) do
    contract_address = Map.get(input, :contract_address)
    minted_burn_address_hash = UDTBalance.minted_burn_address_hash()

    burnt_token_ids =
      from(tt in TokenTransfer,
        where:
          tt.token_contract_address_hash == ^contract_address and
            tt.to_address_hash == ^minted_burn_address_hash,
        distinct: [tt.token_id],
        select: tt.token_id
      )
      |> Repo.all()

    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:token_id, value} ->
            dynamic([cu], ^acc and cu.token_id == ^value)

          _ ->
            acc
        end
      end)

    squery =
      from(cu in CurrentUDTBalance)
      |> where([c], c.token_type == :erc721 and c.token_id not in ^burnt_token_ids)
      |> where([_], ^conditions)
      |> where(
        [cu],
        cu.token_contract_address_hash == ^contract_address and cu.value > 0
      )
      |> order_by([c], desc: :token_id, desc: :block_number, desc: :id)
      |> distinct([c], [c.token_contract_address_hash, c.token_id])

    return =
      from(cu in CurrentUDTBalance)
      |> join(:inner, [cu], scu in subquery(squery), on: cu.id == scu.id)
      |> order_by([_], desc: :token_id)
      |> paginate_query(input, %{
        cursor_fields: [token_id: :desc],
        total_count_primary_key_field: [:id]
      })

    {:ok, return}
  end

  def erc1155_inventory(_, %{input: input} = _args, _) do
    contract_address = Map.get(input, :contract_address)

    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:token_id, value} ->
            dynamic([cu], ^acc and cu.token_id == ^value)

          _ ->
            acc
        end
      end)

    sq =
      from(cu in CurrentUDTBalance)
      |> where([c], c.token_type == :erc1155)
      |> where([_], ^conditions)
      |> where(
        [cu],
        cu.token_contract_address_hash == ^contract_address
      )
      |> group_by([cu], [cu.token_contract_address_hash, cu.token_id])
      |> select([cu], %{
        contract_address_hash: cu.token_contract_address_hash,
        token_id: cu.token_id,
        counts: sum(cu.value)
      })

    query =
      from(u in UDT,
        join: scu in subquery(sq),
        on: u.contract_address_hash == scu.contract_address_hash,
        as: :inventory,
        order_by: [desc: scu.counts, asc: scu.contract_address_hash, desc: scu.token_id],
        select: scu
      )

    return =
      query
      |> paginate_query(input, %{
        cursor_fields: [
          {{:inventory, :counts}, :desc},
          {{:inventory, :contract_address_hash}, :asc},
          {{:inventory, :token_id}, :desc}
        ],
        total_count_primary_key_field: [:contract_address_hash, :token_id]
      })

    {:ok, return}
  end

  def erc1155_user_inventory(_, %{input: input} = _args, _) do
    contract_address = Map.get(input, :contract_address)

    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:token_id, value} ->
            dynamic([cu], ^acc and cu.token_id == ^value)

          _ ->
            acc
        end
      end)

    return =
      from(cu in CurrentUDTBalance)
      |> where([_], ^conditions)
      |> where(
        [cu],
        cu.token_contract_address_hash == ^contract_address and cu.token_type == :erc1155 and
          cu.value > 0
      )
      |> order_by([c], desc: :block_number, desc: :id, desc: :token_id)
      |> paginate_query(input, %{
        cursor_fields: [block_number: :desc, id: :desc, token_id: :desc],
        total_count_primary_key_field: [:address_hash, :token_contract_address_hash, :token_id]
      })

    {:ok, return}
  end

  def name(%{name: name, display_name: display_name}, _args, _resolution) do
    {:ok, display_name || name}
  end

  def symbol(%{symbol: symbol, uan: uan}, _args, _resolution) do
    {:ok, uan || symbol}
  end

  defp base_udts_order_by(holders_count_query, input, only_condition \\ false) do
    sorter = Map.get(input, :sorter)

    order_params =
      sorter
      |> Enum.map(fn e ->
        case e do
          %{sort_type: st, sort_value: :ex_holders_count} ->
            st =
              case st do
                :desc -> :desc_nulls_last
                :asc -> :asc_nulls_first
              end

            {st, dynamic([u_holders: uh], field(uh, :holders_count))}

          %{sort_type: st, sort_value: :minted_count} ->
            {st, dynamic([u_holders: uh], field(uh, :minted_count))}

          %{sort_type: st, sort_value: :token_type_count} ->
            {st, dynamic([u_holders: uh], field(uh, :token_type_count))}

          _ ->
            cursor_order_sorter(e, :order, @sorter_fields)
        end
      end)

    order_params =
      if List.keyfind(order_params, :id, 1) do
        order_params
      else
        order_params ++ [{:asc, :id}]
      end

    if only_condition do
      order_params
    else
      order_by(holders_count_query, ^order_params)
    end
  end
end
