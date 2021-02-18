defmodule GodwokenRPC.Block do
  def from_response(%{id: id, result: nil}, id_to_params) when is_map(id_to_params) do
    params = Map.fetch!(id_to_params, id)

    {:error, %{code: 404, message: "Not Found", data: params}}
  end

  def from_response(%{id: id, result: block}, id_to_params) when is_map(id_to_params) do
    true = Map.has_key?(id_to_params, id)

    {:ok, block}
  end

  def from_response(%{id: id, error: error}, id_to_params) when is_map(id_to_params) do
    params = Map.fetch!(id_to_params, id)
    annotated_error = Map.put(error, :data, params)

    {:error, annotated_error}
  end

  def request(number) do
    json =
      %{ "jsonrpc" => "2.0", "id" => 2, "method" => "gw_getBlockByNumber", "params" => [number]}
      |> Jason.encode!
    case HTTPoison.post(Application.get_env(:godwoken_explorer, :godwoken_rpc_url), json, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{body: body, status_code: status_code}} ->
        {:ok, %{body: body, status_code: status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end


  def elixir_to_params(
        %{
          "hash" => hash,
          "transactions" => transactions,
          "raw" => %{
            "parent_block_hash" => parent_hash,
            "number" => number,
            "timestamp" => timestamp,
            "block_producer_id" => aggregator_id
          }
        }
      ) do
    %{
      hash: hash,
      parent_hash: parent_hash,
      number: number |> String.slice(2..-1) |> String.to_integer(16),
      timestamp: timestamp |> String.slice(2..-1) |> String.to_integer(16) |> timestamp_to_datetime,
      aggregator_id: aggregator_id,
      transaction_count: transactions |> Enum.count()
    }
  end

  defp timestamp_to_datetime(timestamp) do
      timestamp
      |> DateTime.from_unix!()
  end


end
