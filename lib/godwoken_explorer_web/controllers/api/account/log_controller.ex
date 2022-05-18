defmodule GodwokenExplorerWeb.API.Account.LogController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.LogView

  action_fallback(GodwokenExplorerWeb.API.FallbackController)

  plug JSONAPI.QueryParser, view: LogView

  def index(conn, %{"address" => "0x" <> _} = params) do
    results =
      LogView.list_by_address_hash(
        params["address"],
        conn.params["page"] || 1,
        conn.assigns.page_size
      )

    data =
      JSONAPI.Serializer.serialize(LogView, results.entries, conn, %{
        total_page: results.total_pages,
        current_page: results.page_number
      })

    json(conn, data)
  end

  def index(_conn, _) do
    {:error, :not_found}
  end
end
