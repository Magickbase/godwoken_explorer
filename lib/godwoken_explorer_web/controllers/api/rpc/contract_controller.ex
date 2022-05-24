defmodule GodwokenExplorerWeb.API.RPC.ContractController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.Chain

  @invalid_address "Invalid address hash"
  @address_required "Query parameter address is required"

  def getabi(conn, params) do
    with {:address_param, {:ok, address_param}} <- fetch_address(params),
         {:format, {:ok, address_hash}} <- to_address_hash(address_param),
         {:contract, {:ok, contract}} <- to_smart_contract(address_hash) do
      render(conn, :getabi, %{abi: contract.abi})
    else
      {:address_param, :error} ->
        render(conn, :error, error: @address_required)

      {:format, :error} ->
        render(conn, :error, error: @invalid_address)

      {:contract, :not_found} ->
        render(conn, :error, error: "Contract not found")
    end
  end

  def getsourcecode(conn, params) do
    with {:address_param, {:ok, address_param}} <- fetch_address(params),
         {:format, {:ok, address_hash}} <- to_address_hash(address_param),
         {:contract, {:ok, contract}} <- to_smart_contract(address_hash) do
      render(conn, :getabi, %{contract: contract})
    else
      {:address_param, :error} ->
        render(conn, :error, error: @address_required)

      {:format, :error} ->
        render(conn, :error, error: @invalid_address)

      {:contract, :not_found} ->
        render(conn, :error, error: "Contract not found")
    end
  end

  defp fetch_address(params) do
    {:address_param, Map.fetch(params, "address")}
  end

  defp to_address_hash(address_hash_string) do
    {:format, Chain.string_to_address_hash(address_hash_string)}
  end

  defp to_smart_contract(address_hash) do
    result =
      case Chain.address_hash_to_smart_contract(address_hash) do
        nil ->
          :not_found

        contract ->
          {:ok, contract}
      end

    {:contract, result}
  end
end
