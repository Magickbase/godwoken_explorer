defmodule GodwokenExplorer.Graphql.Resolvers.AccountUDT do
  alias GodwokenExplorer.{AccountUDT, UDT, Account}
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]

  @addresses_max_limit 20

  def udt(
        %AccountUDT{udt_id: udt_id, token_contract_address_hash: token_contract_address_hash} =
          _parent,
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

  def account(
        %AccountUDT{token_contract_address_hash: token_contract_address_hash} = _parent,
        _args,
        _resolution
      ) do
    result =
      from(a in Account)
      |> where(
        [a],
        a.eth_address == ^token_contract_address_hash or
          a.script_hash == ^token_contract_address_hash
      )
      |> Repo.one()

    {:ok, result}
  end

  def account_udts(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes)
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    if length(address_hashes) > @addresses_max_limit do
      {:error, :too_many_inputs}
    else
      query = search_account_udts(address_hashes, token_contract_address_hash)

      {:ok, Repo.all(query)}
    end
  end

  def account_udts_by_contract_address(_parent, %{input: input} = _args, _resolution) do
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    return =
      from(au in AccountUDT)
      |> where([au], au.token_contract_address_hash == ^token_contract_address_hash)
      |> sort_type(input, :balance)
      |> page_and_size(input)
      |> Repo.all()

    {:ok, return}
  end

  def account_ckbs(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes)

    ckb_account_id = UDT.ckb_account_id()

    if ckb_account_id do
      do_account_ckbs(address_hashes, ckb_account_id)
    else
      {:error, :ckb_account_not_found}
    end
  end

  defp do_account_ckbs(address_hashes, ckb_account_id) do
    %Account{script_hash: token_contract_address_hash} = Repo.get(Account, ckb_account_id)

    if length(address_hashes) > @addresses_max_limit do
      {:error, :too_many_addresses}
    else
      query = search_account_udts(address_hashes, token_contract_address_hash)
      return = Repo.all(query)

      return_account_udts =
        Enum.map(return, fn au -> %{address_hash: au.address_hash, balance: au.balance} end)

      {:ok, return_account_udts}
    end
  end

  defp search_account_udts(address_hashes, token_contract_address_hash) do
    squery =
      from(a in Account)
      |> where([a], a.eth_address in ^address_hashes)

    query =
      from(au in AccountUDT)
      |> join(:inner, [au], a in subquery(squery), on: au.address_hash == a.eth_address)
      |> join(:inner, [au], a in Account,
        on:
          au.token_contract_address_hash == a.eth_address or
            au.token_contract_address_hash == a.script_hash
      )
      |> join(:inner, [_au, _a1, a2], u in UDT, on: a2.id == u.id or a2.id == u.bridge_account_id)
      |> order_by([au], desc: au.updated_at)
      |> distinct([au, _a1, _a2, u], [au.address_hash, u.id])

    if is_nil(token_contract_address_hash) do
      query
      |> preload([:account])
    else
      query
      |> where([au], au.token_contract_address_hash == ^token_contract_address_hash)
      |> preload([:account])
    end
  end
end
