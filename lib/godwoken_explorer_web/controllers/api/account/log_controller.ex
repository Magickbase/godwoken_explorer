defmodule GodwokenExplorerWeb.API.Account.LogController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{LogView, Chain}

  action_fallback(GodwokenExplorerWeb.API.FallbackController)

  plug JSONAPI.QueryParser, view: LogView

  def index(conn, %{"address" => "0x" <> _} = params) do
    case Chain.string_to_address_hash(params["address"]) do
      {:ok, hash} ->
        results = LogView.list_by_address_hash(hash)

        data = JSONAPI.Serializer.serialize(LogView, results, conn, %{})

        json(conn, data)

      :error ->
        {:error, :address_format}
    end
  end

  def index(_conn, _) do
    {:error, :not_found}
  end
end
