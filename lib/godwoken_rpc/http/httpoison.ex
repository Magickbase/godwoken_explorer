defmodule GodwokenRPC.HTTP.HTTPoison do
  @moduledoc """
  Uses `HTTPoison` for `GodwokenRPC.HTTP`
  """

  alias GodwokenRPC.HTTP

  @behaviour HTTP

  @impl HTTP
  @spec json_rpc(nil | binary, any, any) :: {:error, any} | {:ok, %{body: any, status_code: integer}}
  def json_rpc(url, json, options \\ []) when is_binary(url) and is_list(options) do
    case HTTPoison.post(url, json, [{"Content-Type", "application/json"}], options) do
      {:ok, %HTTPoison.Response{body: body, status_code: status_code}} ->
        {:ok, %{body: body, status_code: status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def json_rpc(url, _json, _options) when is_nil(url), do: {:error, "URL is nil"}
end
