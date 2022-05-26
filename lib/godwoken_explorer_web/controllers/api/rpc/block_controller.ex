defmodule GodwokenExplorerWeb.API.RPC.BlockController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.Chain

  def getblocknobytime(conn, params) do
    with {:timestamp_param, {:ok, unsafe_timestamp}} <-
           {:timestamp_param, Map.fetch(params, "timestamp")},
         {:closest_param, {:ok, unsafe_closest}} <-
           {:closest_param, Map.fetch(params, "closest")},
         {:ok, timestamp} <- Chain.param_to_block_timestamp(unsafe_timestamp),
         {:ok, closest} <- Chain.param_to_block_closest(unsafe_closest),
         {:ok, block_number} <- Chain.timestamp_to_block_number(timestamp, closest) do
      render(conn, :getblocknobytime, block_number: block_number)
    else
      {:timestamp_param, :error} ->
        render(conn, :error, error: "Query parameter 'timestamp' is required")

      {:closest_param, :error} ->
        render(conn, :error, error: "Query parameter 'closest' is required")

      {:error, :invalid_timestamp} ->
        render(conn, :error, error: "Invalid `timestamp` param")

      {:error, :invalid_closest} ->
        render(conn, :error, error: "Invalid `closest` param")

      {:error, :not_found} ->
        render(conn, :error, error: "Block does not exist")
    end
  end
end
