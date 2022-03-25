defmodule GodwokenExplorer.Graphql.Resolvers.AccountUDT do
  alias GodwokenExplorer.AccountUDT
  alias GodwokenExplorer.Repo

  import Ecto.Query

  def account_udts(_parent, %{input: inputs} = _args, _resolution) do
    {:ok, get_by_addresses_and_contract_address(inputs)}
  end

  def account_udts_by_contract_address(_parent, %{input: input} = _args, _resolution) do
    {:ok, get_account_udts_by_contract_address(input)}
  end

  # TODO: find account ckbs by two address
  def account_ckbs(_parent, _args, _resolution) do
    {:ok, nil}
  end

  #####################
  ### private function
  #####################

  defp get_account_udts_by_contract_address(input) do
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    Repo.all(
      from au in AccountUDT,
        where: au.token_contract_address_hash == ^token_contract_address_hash,
        limit: 100,
        order_by: [desc: au.updated_at]
    )
  end

  defp get_by_addresses_and_contract_address(input) do
    address_hashes = Map.get(input, :address_hashes)
    token_contract_address_hash = Map.get(input, :token_contract_address_hash)

    Repo.all(
      from au in AccountUDT,
        where:
          au.token_contract_address_hash == ^token_contract_address_hash and
            au.address_hash in ^address_hashes
    )
  end
end
