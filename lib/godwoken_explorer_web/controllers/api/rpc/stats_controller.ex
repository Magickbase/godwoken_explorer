defmodule GodwokenExplorerWeb.API.RPC.StatsController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Chain}

  def tokensupply(conn, params) do
    with {:contractaddress_param, {:ok, contractaddress_param}} <- fetch_contractaddress(params),
         {:format, {:ok, address_hash}} <- to_address_hash(contractaddress_param),
         {:token, {:ok, supply}} <- {:token, Chain.token_from_address_hash(address_hash)} do
      render(conn, "tokensupply.json", total_supply: Decimal.to_string(supply))
    else
      {:contractaddress_param, :error} ->
        render(conn, :error, error: "Query parameter contract address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid contract address format")

      {:token, {:error, :not_found}} ->
        render(conn, :error, error: "contract address not found")
    end
  end

  defp fetch_contractaddress(params) do
    {:contractaddress_param, Map.fetch(params, "contractaddress")}
  end

  defp to_address_hash(address_hash_string) do
    {:format, Chain.string_to_address_hash(address_hash_string)}
  end
end
