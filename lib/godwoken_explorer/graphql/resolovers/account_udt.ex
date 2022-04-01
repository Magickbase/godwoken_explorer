defmodule GodwokenExplorer.Graphql.Resolvers.AccountUDT do
  alias GodwokenExplorer.{AccountUDT, UDT, Account}
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2]

  @addresses_max_limit 20

  def udt(%AccountUDT{udt_id: udt_id} = _parent, _args, _resolution) do
    return = Repo.get(UDT, udt_id)
    {:ok, return}
  end

  def account(%AccountUDT{account_id: account_id} = _parent, _args, _resolution) do
    return = Repo.get(Account, account_id)
    {:ok, return}
  end

  def account_udts(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes)
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    query =
      from(au in AccountUDT)
      |> where(
        [au],
        au.token_contract_address_hash == ^token_contract_address_hash and
          au.address_hash in ^address_hashes
      )

    if length(address_hashes) > @addresses_max_limit do
      {:error, :too_many_inputs}
    else
      return = Repo.all(query)
      {:ok, return}
    end
  end

  def account_udts_by_contract_address(_parent, %{input: input} = _args, _resolution) do
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    return =
      from(au in AccountUDT)
      |> where([au], au.token_contract_address_hash == ^token_contract_address_hash)
      |> order_by([au], desc: au.updated_at)
      |> page_and_size(input)
      |> Repo.all()

    {:ok, return}
  end

  def account_ckbs(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes)

    ckb_account_id = UDT.ckb_account_id()
    %Account{short_address: token_contract_address_hash} = Repo.get(Account, ckb_account_id)

    query =
      from(au in AccountUDT)
      |> where(
        [au],
        au.token_contract_address_hash == ^token_contract_address_hash and
          au.address_hash in ^address_hashes
      )

    if length(address_hashes) > @addresses_max_limit do
      {:error, :too_many_addresses}
    else
      return = Repo.all(query)
      {:ok, return}
    end
  end
end
