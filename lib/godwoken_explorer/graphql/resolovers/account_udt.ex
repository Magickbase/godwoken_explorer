defmodule GodwokenExplorer.Graphql.Resolvers.AccountUDT do
  alias GodwokenExplorer.AccountUDT
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.PageAndSize, only: [page_and_size: 2]

  @addresses_max_limit 20

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

    layer2_ckb_smart_contract_address_1 =
      Application.get_env(:godwoken_explorer, :special_address)[
        :layer2_ckb_smart_contract_address_1
      ]

    layer2_ckb_smart_contract_address_2 =
      Application.get_env(:godwoken_explorer, :special_address)[
        :layer2_ckb_smart_contract_address_2
      ]

    smart_contract_addresses = [
      layer2_ckb_smart_contract_address_1,
      layer2_ckb_smart_contract_address_2
    ]

    query =
      from(au in AccountUDT)
      |> where(
        [au],
        au.token_contract_address_hash in ^smart_contract_addresses and
          au.address_hash in ^address_hashes
      )

    if length(address_hashes) > @addresses_max_limit do
      {:error, :too_many_inputs}
    else
      return = Repo.all(query)
      {:ok, return}
    end
  end
end
