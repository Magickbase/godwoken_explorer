defmodule GodwokenRpc.Block do
  def fetch(number) do
    url = "http://localhost:8119"
    json =
      %{ "jsonrpc" => "2.0", "id" => 2, "method" => "gw_getBlockByNumber", "params" => [number]}
      |> Jason.encode!
    case HTTPoison.post(url, json, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{body: body, status_code: status_code}} ->
        {:ok, %{body: body, status_code: status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
