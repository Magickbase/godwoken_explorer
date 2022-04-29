defmodule GodwokenExplorer.Graphql.Resolvers.AccountUDT do
  alias GodwokenExplorer.{AccountUDT, UDT, Account}
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]

  @addresses_max_limit 20

  def udt(%AccountUDT{udt_id: udt_id} = _parent, _args, _resolution) do
    if udt_id do
      {:ok, Repo.get(UDT, udt_id)}
    else
      {:ok, nil}
    end
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
    %Account{short_address: token_contract_address_hash} = Repo.get(Account, ckb_account_id)

    if length(address_hashes) > @addresses_max_limit do
      {:error, :too_many_addresses}
    else
      query = search_account_udts(address_hashes, token_contract_address_hash)
      return = Repo.all(query)
      {:ok, return}
    end
  end

  defp search_account_udts(address_hashes, token_contract_address_hash) do
    squery =
      from(a in Account)
      |> where([a], a.eth_address in ^address_hashes or a.short_address in ^address_hashes)

    query =
      from(au in AccountUDT)
      |> join(:inner, [au], a in subquery(squery),
        on: au.address_hash == a.short_address or au.address_hash == a.eth_address
      )
      |> select([au, _a], au)
      |> order_by([au], au.updated_at)
      |> distinct([au], [au.address_hash, au.token_contract_address_hash])

    if is_nil(token_contract_address_hash) do
      query
    else
      query
      |> where([au], au.token_contract_address_hash == ^token_contract_address_hash)
    end
  end
end
