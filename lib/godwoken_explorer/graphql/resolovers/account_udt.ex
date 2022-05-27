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

  def account(%AccountUDT{account_id: account_id} = _parent, _args, _resolution) do
    if account_id do
      {:ok, Repo.get(Account, account_id)}
    else
      {:ok, nil}
    end
  end

  def account_udts(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes)
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    if length(address_hashes) > @addresses_max_limit do
      {:error, :too_many_inputs}
    else
      query = search_account_udts(address_hashes, token_contract_address_hash)
      return = Repo.all(query)
      {:ok, return}
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
      {:error, :no_ckb_account}
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

      filted_address_hashes =
        Enum.filter(address_hashes, fn address_hash ->
          not Enum.any?(return, fn au ->
            au.account.eth_address == address_hash
          end)
        end)

      need_rpc_fetched_address_hashes =
        filted_address_hashes
        |> Enum.map(fn address_hash -> fetch_account_cks(address_hash) end)
        |> Enum.filter(&(not is_nil(&1)))

      {:ok, return_account_udts ++ need_rpc_fetched_address_hashes}
    end
  end

  defp fetch_account_cks(address_hash) do
    with account when not is_nil(account) <-
           Repo.one(
             from a in Account,
               where: ^address_hash == a.eth_address
           ),
         udt_id when is_integer(udt_id) <- UDT.ckb_account_id(),
         {:ok, balance} <- GodwokenRPC.fetch_balance(account.registry_address, udt_id) do
      %{
        address_hash: address_hash,
        # be string for graphql custom decimal type
        balance: Decimal.new(balance)
      }
    else
      _ -> nil
    end
  end

  defp search_account_udts(address_hashes, token_contract_address_hash) do
    squery =
      from(a in Account)
      |> where([a], a.eth_address in ^address_hashes)

    query =
      from(au in AccountUDT)
      |> join(:inner, [au], a in subquery(squery), on: au.address_hash == a.eth_address)
      |> select([au, _a], au)
      |> order_by([au], au.updated_at)
      |> distinct([au], [au.address_hash, au.token_contract_address_hash])

    query =
      if is_nil(token_contract_address_hash) do
        query
      else
        query
        |> where([au], au.token_contract_address_hash == ^token_contract_address_hash)
      end

    preload(query, [:account])
  end
end
