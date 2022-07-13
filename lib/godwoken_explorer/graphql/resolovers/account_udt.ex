defmodule GodwokenExplorer.Graphql.Resolvers.AccountUDT do
  alias GodwokenExplorer.{UDT, Account}
  alias GodwokenExplorer.Account.{CurrentUDTBalance, CurrentBridgedUDTBalance}

  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]

  @addresses_max_limit 20

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
      |> join(:inner, [cu], a1 in subquery(squery), on: cu.address_hash == a1.eth_address)
      |> join(:inner, [cu], u in UDT,
        on: u.contract_address_hash == cu.token_contract_address_hash
      )
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
      query = search_account_current_brideged_udts(address_hashes, script_hashes, udt_script_hash)

      {:ok, Repo.all(query)}
    end
  end

  defp search_account_current_brideged_udts_with_address(_address_hashes, _script_hashes, nil),
    do: []

  defp search_account_current_brideged_udts_with_address(
         address_hashes,
         script_hashes,
         udt_script_hash
       ) do
    search_account_current_brideged_udts(address_hashes, script_hashes, udt_script_hash)
    |> Repo.all()
  end

  defp search_account_current_brideged_udts(address_hashes, script_hashes, udt_script_hash) do
    squery =
      from(a in Account)
      |> where([a], a.eth_address in ^address_hashes or a.script_hash in ^script_hashes)

    Repo.all(squery)

    query =
      from(cbu in CurrentBridgedUDTBalance)
      |> join(:inner, [cbu], a1 in subquery(squery), on: cbu.address_hash == a1.eth_address)
      |> join(:inner, [cbu], a2 in Account, on: cbu.udt_script_hash == a2.script_hash)
      |> join(:inner, [_cbu, _a1, a2], u in UDT, on: u.id == a2.id)
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

  defp do_udt(%CurrentUDTBalance{
         udt_id: udt_id,
         token_contract_address_hash: token_contract_address_hash
       }) do
    if udt_id do
      from(u in UDT)
      |> where([u], u.id == ^udt_id)
      |> Repo.one()
    else
      result =
        from(u in UDT)
        |> where([u], u.contract_address_hash == ^token_contract_address_hash)
        |> first()
        |> Repo.all()

      if result == [] do
        nil
      else
        hd(result)
      end
    end
  end

  defp do_udt(
         %CurrentBridgedUDTBalance{udt_id: udt_id, udt_script_hash: udt_script_hash} = _parent
       ) do
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

  def account(
        %CurrentUDTBalance{token_contract_address_hash: token_contract_address_hash} = _parent,
        _args,
        _resolution
      ) do
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
        %CurrentBridgedUDTBalance{udt_script_hash: udt_script_hash} = _parent,
        _args,
        _resolution
      ) do
    result =
      from(a in Account)
      |> where(
        [a],
        a.script_hash == ^udt_script_hash
      )
      |> Repo.one()

    {:ok, result}
  end

  def account_udts_by_contract_address(_parent, %{input: input} = _args, _resolution) do
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    return =
      from(cu in CurrentUDTBalance)
      |> where([cu], cu.token_contract_address_hash == ^token_contract_address_hash)
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
        search_account_current_brideged_udts(
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
        |> Enum.sort_by(&Map.fetch(&1, :updated_at))
        |> Enum.uniq_by(&Map.fetch(&1, :address_hash))

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
        |> join(:inner, [a], u in UDT, on: a.id == u.bridge_account_id)
        |> join(:inner, [a, u], a2 in Account, on: a2.id == u.id)
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
          search_account_current_brideged_udts_with_address(
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

        result =
          (cbus ++ cus)
          |> Enum.sort_by(&Map.fetch(&1, :updated_at), :desc)
          |> Enum.uniq_by(&Map.fetch(&1, :address_hash))

        {:ok, result}
      else
        {:error, :need_token_contract_address_hash_or_udt_script_hash}
      end
    end
  end
end
