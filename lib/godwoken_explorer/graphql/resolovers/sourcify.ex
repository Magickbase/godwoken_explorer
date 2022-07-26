defmodule GodwokenExplorer.Graphql.Resolvers.Sourcify do
  alias GodwokenExplorer.Graphql.Sourcify
  alias GodwokenExplorer.Chain.Hash.Address

  alias GodwokenExplorer.{Account, Polyjuice, SmartContract, Transaction}

  alias GodwokenExplorer.Admin.SmartContract, as: AdminSmartContract
  alias GodwokenExplorer.Repo

  import Ecto.Query

  def check_by_addresses(_parent, %{input: input} = _args, _resolution) do
    addresses =
      Map.get(input, :addresses)
      |> Enum.map(fn e -> to_string(e) end)
      |> Enum.join(",")

    case Sourcify.check_by_addresses(addresses) do
      {:error, _} = error ->
        error

      {:ok, return} ->
        return = process_check_by_addresses_result(return)

        {:ok, return}
    end
  end

  defp process_check_by_addresses_result(return) do
    Enum.map(return, fn r ->
      r = r |> Jason.encode!() |> Jason.decode!(keys: :atoms)
      {:ok, address} = Address.cast(r[:address])

      r
      |> Map.put(:chain_ids, r[:chainIds])
      |> Map.put(:address, address)
    end)
  end

  def verify_and_publish(_parent, %{input: %{address: address}} = _args, _resolution) do
    address_hash_string = address |> to_string()

    case Sourcify.check_by_addresses(address_hash_string) do
      {:ok, _verified} ->
        case Sourcify.get_metadata(address_hash_string) do
          {:ok, verification_metadata} ->
            case Sourcify.parse_params_from_sourcify(address_hash_string, verification_metadata) do
              %{
                "params_to_publish" => params_to_publish,
                "abi" => abi
              } ->
                %{
                  "name" => name,
                  "compiler_version" => compiler_version,
                  # "optimization" => optimization,
                  "contract_source_code" => contract_source_code
                } = params_to_publish

                deployment_tx_hash = find_deployment_tx_hash(address)

                smart_contract_params = %{
                  name: name,
                  abi: abi,
                  compiler_version: compiler_version,
                  contract_source_code: contract_source_code,
                  deployment_tx_hash: deployment_tx_hash
                }

                update_smart_contract_from_sourcify(address, smart_contract_params)

              {:error, :metadata} ->
                {:error, Sourcify.no_metadata_message()}

              _ ->
                {:error, Sourcify.failed_verification_message()}
            end

          {:error, %{"error" => error}} ->
            {:error, inspect(error)}
        end

      {:error, _} = error ->
        error
    end
  end

  def find_deployment_tx_hash(address) when is_bitstring(address) do
    {:ok, address} = Address.cast(address)
    find_deployment_tx_hash(address)
  end

  def find_deployment_tx_hash(address) do
    from(p in Polyjuice,
      where: p.created_contract_address_hash == ^address,
      join: t in Transaction,
      on: t.hash == p.tx_hash,
      select: t.eth_hash
    )
    |> Repo.one()
  end

  defp update_smart_contract_from_sourcify(address, attrs) do
    account = Repo.get_by(Account, eth_address: address)

    if account do
      smart_contract = Repo.get_by(SmartContract, account_id: account.id)

      if smart_contract do
        AdminSmartContract.update_smart_contract(smart_contract, attrs)
      else
        params = attrs |> Map.merge(%{account_id: account.id})
        AdminSmartContract.create_smart_contract(params)
      end
    else
      {:error, "contract account not found"}
    end
  end
end
