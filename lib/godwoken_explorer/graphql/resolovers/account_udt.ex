defmodule GodwokenExplorer.Graphql.Resolvers.AccountUDT do
  alias GodwokenExplorer.{UDT, Account}
  alias GodwokenExplorer.Account.{CurrentUDTBalance, CurrentBridgedUDTBalance}

  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]
  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]

  @addresses_max_limit 20

  def account_udt_holders(_parent, %{input: input} = _args, _resolution) do
    udt_id = Map.get(input, :udt_id)

    [udt_script_hash, token_contract_address_hash] = UDT.list_address_by_udt_id(udt_id)

    base_query =
      cond do
        is_nil(udt_script_hash) ->
          cub_holders_query(token_contract_address_hash)

        is_nil(token_contract_address_hash) ->
          cbub_holders_query(udt_script_hash)

        true ->
          bridged_udt_balance_query = cbub_holders_query(udt_script_hash)

          udt_balance_query = cub_holders_query(token_contract_address_hash)

          from(q in subquery(union_all(udt_balance_query, ^bridged_udt_balance_query)),
            join: a in Account,
            on: a.eth_address == q.eth_address,
            select: %{
              eth_address: q.eth_address,
              balance:
                fragment(
                  "CASE WHEN ? is null THEN 0::decimal ELSE ? END",
                  q.balance,
                  q.balance
                ),
              tx_count:
                fragment(
                  "CASE WHEN ? is null THEN 0 ELSE ? END",
                  a.transaction_count,
                  a.transaction_count
                )
            },
            order_by: [desc: :updated_at],
            distinct: q.eth_address
          )
      end

    from(a in Account,
      right_join: sq in subquery(base_query),
      as: :processed,
      on: a.eth_address == sq.eth_address,
      order_by: [desc: sq.balance, desc: sq.eth_address],
      select: %{
        bit_alias: a.bit_alias,
        eth_address: sq.eth_address,
        balance: sq.balance,
        tx_count: sq.tx_count
      }
    )
    |> paginate_query(input, %{
      cursor_fields: [{{:processed, :balance}, :desc}, {{:processed, :eth_address}, :desc}],
      total_count_primary_key_field: [:eth_address]
    })
    |> do_account_udt_holders(udt_id)
  end

  defp do_account_udt_holders({:error, {:not_found, []}}, _), do: {:ok, nil}
  defp do_account_udt_holders({:error, _} = error, _), do: error

  defp do_account_udt_holders(result, udt_id) do
    %UDT{decimal: decimal} = Repo.get_by(UDT, id: udt_id)

    entries =
      Enum.map(result.entries, fn r ->
        %{r | balance: Decimal.div(r.balance, Integer.pow(10, decimal || 0))}
      end)

    result = %{result | entries: entries}

    {:ok, result}
  end

  defp cbub_holders_query(token_address) when not is_nil(token_address) do
    from(cbub in CurrentBridgedUDTBalance,
      where: cbub.udt_script_hash == ^token_address and cbub.value > 0,
      select: %{
        eth_address: cbub.address_hash,
        balance: cbub.value,
        updated_at: cbub.updated_at
      }
    )
  end

  defp cub_holders_query(token_address) when not is_nil(token_address) do
    from(cub in CurrentUDTBalance,
      join: a1 in Account,
      on: a1.eth_address == cub.address_hash,
      where:
        cub.token_contract_address_hash == ^token_address and
          cub.value > 0,
      select: %{
        eth_address: cub.address_hash,
        balance: cub.value,
        updated_at: cub.updated_at
      }
    )
  end

  def account_current_udts(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes)
    script_hashes = Map.get(input, :script_hashes)
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    if length(address_hashes) > @addresses_max_limit or
         length(script_hashes) > @addresses_max_limit do
      {:error, :too_many_inputs}
    else
      query =
        search_account_current_udts(address_hashes, script_hashes, token_contract_address_hash)

      {:ok, Repo.all(query)}
    end
  end

  defp search_account_current_udts_with_address(_address_hashes, _script_hashes, nil), do: []

  defp search_account_current_udts_with_address(
         address_hashes,
         script_hashes,
         token_contract_address_hash
       ) do
    search_account_current_udts(address_hashes, script_hashes, token_contract_address_hash)
    |> Repo.all()
  end

  defp search_account_current_udts(address_hashes, script_hashes, token_contract_address_hash) do
    squery =
      from(a in Account)
      |> where([a], a.eth_address in ^address_hashes or a.script_hash in ^script_hashes)

    query =
      from(cu in CurrentUDTBalance)
      |> where([cu], cu.token_type == :erc20)
      |> join(:inner, [cu], a1 in subquery(squery), on: cu.address_hash == a1.eth_address)
      |> join(:inner, [cu], u in UDT,
        on: u.contract_address_hash == cu.token_contract_address_hash
      )
      |> where(
        [cu, _a1, u],
        not is_nil(u.name)
      )
      |> select([cu, _a1, u], %{
        value: cu.value,
        address_hash: cu.address_hash,
        token_contract_address_hash: cu.token_contract_address_hash,
        udt_script_hash: nil,
        udt_id: u.id,
        uniq_id: u.id,
        updated_at: cu.updated_at
      })
      |> order_by([cu], desc: cu.updated_at)

    if is_nil(token_contract_address_hash) do
      query
    else
      query
      |> where([cu], cu.token_contract_address_hash == ^token_contract_address_hash)
    end
  end

  def account_current_bridged_udts(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes)
    script_hashes = Map.get(input, :script_hashes)
    udt_script_hash = Map.get(input, :udt_script_hash)

    if length(address_hashes) > @addresses_max_limit or
         length(script_hashes) > @addresses_max_limit do
      {:error, :too_many_inputs}
    else
      query = search_account_current_bridged_udts(address_hashes, script_hashes, udt_script_hash)

      {:ok, Repo.all(query)}
    end
  end

  defp search_account_current_bridged_udts_with_address(_address_hashes, _script_hashes, nil),
    do: []

  defp search_account_current_bridged_udts_with_address(
         address_hashes,
         script_hashes,
         udt_script_hash
       ) do
    search_account_current_bridged_udts(address_hashes, script_hashes, udt_script_hash)
    |> Repo.all()
  end

  defp search_account_current_bridged_udts(address_hashes, script_hashes, udt_script_hash) do
    squery =
      from(a in Account)
      |> where([a], a.eth_address in ^address_hashes or a.script_hash in ^script_hashes)

    query =
      from(cbu in CurrentBridgedUDTBalance)
      |> join(:inner, [cbu], a1 in subquery(squery), on: cbu.address_hash == a1.eth_address)
      |> join(:inner, [cbu], a2 in Account, on: cbu.udt_script_hash == a2.script_hash)
      |> join(:inner, [cbu, _a1, a2], u in UDT, on: u.id == a2.id)
      |> where(
        [cbu, _a1, _a2, u],
        not is_nil(u.bridge_account_id)
      )
      |> select(
        [cbu, _a1, _a2, u],
        %{
          value: cbu.value,
          address_hash: cbu.address_hash,
          token_contract_address_hash: nil,
          udt_script_hash: cbu.udt_script_hash,
          udt_id: u.id,
          uniq_id: u.bridge_account_id,
          updated_at: cbu.updated_at
        }
      )
      |> order_by([cbu], desc: cbu.updated_at)

    if is_nil(udt_script_hash) do
      query
    else
      query
      |> where([au], au.udt_script_hash == ^udt_script_hash)
    end
  end

  def udt(parent, _args, _resolution) do
    return = do_udt(parent)
    {:ok, return}
  end

  defp do_udt(%{
         udt_id: udt_id,
         token_contract_address_hash: token_contract_address_hash
       })
       when not is_nil(token_contract_address_hash) do
    if udt_id do
      case Repo.get(UDT, udt_id) do
        nil ->
          a = Repo.get(Account, udt_id)
          %UDT{id: udt_id, contract_address_hash: a.eth_address}

        %UDT{} = u ->
          u
      end
    else
      Repo.get_by(UDT, contract_address_hash: token_contract_address_hash)
    end
  end

  defp do_udt(%{udt_id: udt_id, udt_script_hash: udt_script_hash} = _parent)
       when not is_nil(udt_script_hash) do
    if udt_id do
      from(u in UDT)
      |> where([u], u.id == ^udt_id)
      |> Repo.one()
    else
      result =
        from(u in UDT)
        |> join(:inner, [u], a in Account, on: a.script_hash == ^udt_script_hash and u.id == a.id)
        |> order_by([u], desc: u.updated_at)
        |> first()
        |> Repo.all()

      if result == [] do
        nil
      else
        hd(result)
      end
    end
  end

  defp do_udt(%{udt_id: udt_id}) do
    %UDT{id: udt_id}
  end

  def account(
        %{token_contract_address_hash: token_contract_address_hash} = _parent,
        _args,
        _resolution
      )
      when not is_nil(token_contract_address_hash) do
    result =
      from(a in Account)
      |> where(
        [a],
        a.eth_address == ^token_contract_address_hash
      )
      |> Repo.one()

    {:ok, result}
  end

  def account(
        %{udt_script_hash: udt_script_hash} = _parent,
        _args,
        _resolution
      )
      when not is_nil(udt_script_hash) do
    result =
      from(a in Account)
      |> where(
        [a],
        a.script_hash == ^udt_script_hash
      )
      |> Repo.one()

    {:ok, result}
  end

  def account(_, _, _), do: {:ok, nil}

  def account_udts_by_contract_address(_parent, %{input: input} = _args, _resolution) do
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    return =
      from(cu in CurrentUDTBalance)
      |> where(
        [cu],
        cu.token_contract_address_hash == ^token_contract_address_hash and cu.token_type == :erc20
      )
      |> sort_type(input, :value)
      |> page_and_size(input)
      |> Repo.all()

    {:ok, return}
  end

  def account_bridged_udts_by_script_hash(_parent, %{input: input} = _args, _resolution) do
    udt_script_hash = Map.get(input, :udt_script_hash)

    return =
      from(cbu in CurrentBridgedUDTBalance)
      |> where([cbu], cbu.udt_script_hash == ^udt_script_hash)
      |> sort_type(input, :value)
      |> page_and_size(input)
      |> Repo.all()

    {:ok, return}
  end

  def account_ckbs(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes)
    script_hashes = Map.get(input, :script_hashes)
    ckb_account_id = UDT.ckb_account_id()

    if ckb_account_id do
      [ckb_bridged_address, ckb_contract_address] =
        UDT.ckb_account_id() |> UDT.list_address_by_udt_id()

      cbus =
        search_account_current_bridged_udts(
          address_hashes,
          script_hashes,
          ckb_bridged_address
        )
        |> Repo.all()

      cus =
        search_account_current_udts(address_hashes, script_hashes, ckb_contract_address)
        |> Repo.all()

      result =
        (cbus ++ cus)
        |> Enum.sort_by(&{&1.uniq_id, &1.updated_at}, &account_udts_compare_function/2)
        |> Enum.uniq_by(& &1.address_hash)

      {:ok, result}
    else
      {:error, :ckb_account_not_found}
    end
  end

  def account_udts(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes)
    script_hashes = Map.get(input, :script_hashes)
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)
    udt_script_hash = Map.get(input, :udt_script_hash)

    account_query =
      if token_contract_address_hash do
        from(a in Account, where: a.eth_address == ^token_contract_address_hash)
        |> join(:left, [a], u in UDT, on: a.id == u.bridge_account_id)
        |> join(:left, [a, u], a2 in Account, on: a2.id == u.id)
        |> select([a, _, a2], %{
          token_contract_address_hash: a.eth_address,
          udt_script_hash: a2.script_hash
        })
      else
        if udt_script_hash do
          from(a in Account, where: a.script_hash == ^udt_script_hash)
          |> join(:inner, [a], u in UDT, on: a.id == u.id)
          |> join(:left, [a, u], a2 in Account, on: a2.id == u.bridge_account_id)
          |> select([a, _, a2], %{
            token_contract_address_hash: a2.eth_address,
            udt_script_hash: a.script_hash
          })
        else
          nil
        end
      end

    if length(address_hashes) > @addresses_max_limit or
         length(script_hashes) > @addresses_max_limit do
      {:error, :too_many_inputs}
    else
      if account_query do
        address_map = Repo.one(account_query)

        cbus =
          search_account_current_bridged_udts_with_address(
            address_hashes,
            script_hashes,
            address_map[:udt_script_hash]
          )

        cus =
          search_account_current_udts_with_address(
            address_hashes,
            script_hashes,
            address_map[:token_contract_address_hash]
          )

        result = process_cus_cbus_balance(cus, cbus)

        {:ok, result}
      else
        cus =
          from(cu in CurrentUDTBalance)
          |> where(
            [cu],
            cu.address_hash in ^address_hashes and cu.token_type == :erc20
          )
          |> join(:inner, [cu], u in UDT,
            on: u.contract_address_hash == cu.token_contract_address_hash
          )
          |> where([cu, u], not is_nil(u.name))
          |> select([cu, u], %{
            value: cu.value,
            address_hash: cu.address_hash,
            token_contract_address_hash: cu.token_contract_address_hash,
            udt_script_hash: nil,
            udt_id: u.id,
            uniq_id: u.id,
            updated_at: cu.updated_at
          })
          |> Repo.all()

        cbus =
          from(cbu in CurrentBridgedUDTBalance)
          |> where(
            [cbu],
            cbu.address_hash in ^address_hashes
          )
          |> join(:inner, [cbu], u in UDT, on: cbu.udt_id == u.id)
          |> where([cbu, u], not is_nil(u.bridge_account_id))
          |> select(
            [cbu, u],
            %{
              value: cbu.value,
              address_hash: cbu.address_hash,
              token_contract_address_hash: nil,
              udt_script_hash: cbu.udt_script_hash,
              udt_id: u.id,
              uniq_id: u.bridge_account_id,
              updated_at: cbu.updated_at
            }
          )
          |> Repo.all()

        result = process_cus_cbus_balance(cus, cbus)

        {:ok, result}
      end
    end
  end

  defp process_cus_cbus_balance(cus, cbus) do
    cus_cubs = cus ++ cbus

    cus_cubs
    |> Enum.sort_by(&{&1.uniq_id, &1.updated_at}, &account_udts_compare_function/2)
    |> Enum.reduce({[], nil}, fn c_cb, {acc_list, base} ->
      case base do
        %{uniq_id: uniq_id} ->
          if c_cb.uniq_id == uniq_id do
            c_cb = %{c_cb | value: base.value}
            {[c_cb | acc_list], c_cb}
          else
            {[c_cb | acc_list], c_cb}
          end

        nil ->
          {[c_cb | acc_list], c_cb}
      end
    end)
    |> (fn {a, _} -> a end).()
    |> Enum.reverse()
    |> Enum.map(fn e ->
      if Enum.find(cus_cubs, fn x -> x.uniq_id == e.uniq_id and x.udt_id != e.udt_id end) do
        e
      else
        if e.udt_id != e.uniq_id do
          [
            e,
            %{
              address_hash: e.address_hash,
              value: e.value,
              udt_id: e.uniq_id,
              uniq_id: e.uniq_id
            }
          ]
        else
          e
        end
      end
    end)
    |> List.flatten()
  end

  def account_udts_compare_function({a1, a2}, {b1, b2}) do
    if a1 != b1 do
      a1 < b1
    else
      case DateTime.compare(a2, b2) do
        :gt -> true
        :eq -> true
        _ -> false
      end
    end
  end
end
