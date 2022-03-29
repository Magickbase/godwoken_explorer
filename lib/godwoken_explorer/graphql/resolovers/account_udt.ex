defmodule GodwokenExplorer.Graphql.Resolvers.AccountUDT do
  alias GodwokenExplorer.AccountUDT
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.PageAndSize, only: [page_and_size: 2]

  def account_udts(_parent, %{input: input} = _args, _resolution) do
    address_hashes = Map.get(input, :address_hashes, [])
    token_contract_address_hash = Map.get(input, :token_contract_address_hash, "")

    return =
      from(au in AccountUDT)
      |> where(
        [au],
        au.token_contract_address_hash == ^token_contract_address_hash and
          au.address_hash in ^address_hashes
      )
      |> Repo.all()

    {:ok, return}
  end

  def account_udts_by_contract_address(_parent, %{input: input} = _args, _resolution) do
    token_contract_address_hash = Map.get(input, :token_contract_address_hash, "")

    return =
      from(au in AccountUDT)
      |> where([au], au.token_contract_address_hash == ^token_contract_address_hash)
      |> order_by([au], desc: au.updated_at)
      |> page_and_size(input)
      |> Repo.all()

    {:ok, return}
  end

  # TODO: find account ckbs by two address
  def account_ckbs(_parent, _args, _resolution) do
    {:ok, nil}
  end
end
