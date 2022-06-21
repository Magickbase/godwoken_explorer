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

  defp search_account_current_udts(address_hashes, script_hashes, token_contract_address_hash) do
    squery =
      from(a in Account)
      |> where([a], a.eth_address in ^address_hashes or a.script_hash in ^script_hashes)

    query =
      from(cu in CurrentUDTBalance)
      |> join(:inner, [cu], a1 in subquery(squery), on: cu.address_hash == a1.eth_address)
      |> join(:inner, [cu, _a1], a2 in Account, on: cu.token_contract_address_hash == a2.eth_address)
      |> join(:inner, [_cu, _a1, a2], u in UDT, on: u.id == a2.id)
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

  defp search_account_current_brideged_udts(address_hashes, script_hashes, udt_script_hash) do
    squery =
      from(a in Account)
      |> where([a], a.eth_address in ^address_hashes or a.script_hash in ^script_hashes)

    Repo.all(squery) |> IO.inspect(label: :xxxx)

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

  def udt(
        %CurrentUDTBalance{
          udt_id: udt_id,
          token_contract_address_hash: token_contract_address_hash
        } = _parent,
        _args,
        _resolution
      ) do
    return =
      if udt_id do
        from(u in UDT)
        |> where([u], u.id == ^udt_id)
        |> Repo.one()
      else
        result =
          from(u in UDT)
          |> join(:inner, [u], a in Account,
            on: a.eth_address == ^token_contract_address_hash and u.bridge_account_id == a.id
          )
          |> order_by([u], desc: u.updated_at)
          |> first()
          |> Repo.all()

        if result == [] do
          nil
        else
          hd(result)
        end
      end

    {:ok, return}
  end

  def udt(
        %CurrentBridgedUDTBalance{udt_id: udt_id, udt_script_hash: udt_script_hash} = _parent,
        _args,
        _resolution
      ) do
    return =
      if udt_id do
        from(u in UDT)
        |> where([u], u.id == ^udt_id)
        |> Repo.one()
      else
        result =
          from(u in UDT)
          |> join(:inner, [u], a in Account,
            on: a.script_hash == ^udt_script_hash and u.id == a.id
          )
          |> order_by([u], desc: u.updated_at)
          |> first()
          |> Repo.all()

        if result == [] do
          nil
        else
          hd(result)
        end
      end

    {:ok, return}
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
      do_account_ckbs(address_hashes, script_hashes, ckb_account_id)
    else
      {:error, :ckb_account_not_found}
    end
  end

  defp do_account_ckbs(address_hashes, script_hashes, ckb_account_id) do
    %Account{script_hash: token_contract_address_hash} = Repo.get(Account, ckb_account_id)

    if length(address_hashes) > @addresses_max_limit do
      {:error, :too_many_addresses}
    else
      query =
        search_account_current_brideged_udts(
          address_hashes,
          script_hashes,
          token_contract_address_hash
        )

      return = Repo.all(query)

      {:ok, return}
    end
  end
end
