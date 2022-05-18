defmodule GodwokenExplorerWeb.API.Account.LogController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.LogView

  action_fallback(GodwokenExplorerWeb.API.FallbackController)

  plug JSONAPI.QueryParser, view: LogView

  def index(conn, %{"address" => "0x" <> _} = params) do
    results = LogView.list_by_address_hash(params["address"])

    data = JSONAPI.Serializer.serialize(LogView, results, conn, %{})

    json(conn, data)
  end

  def index(_conn, _) do
    {:error, :not_found}
  end
end
