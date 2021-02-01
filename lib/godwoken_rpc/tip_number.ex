defmodule GodwokenRpc.TipNumber do
  def request do
    json =
      %{ "jsonrpc" => "2.0", "id" => 2, "method" => "gw_getTipBlockNumber"}
      |> Jason.encode!
    case HTTPoison.post(Application.get_env(:godwoken_explorer, :godwoken_rpc_url), json, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{body: body, status_code: status_code}} ->
        {:ok, %{body: body, status_code: status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
