defmodule GodwokenExplorerWeb.API.SmartContractController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{SmartContractView}

  plug JSONAPI.QueryParser, view: SmartContractView
  action_fallback GodwokenExplorerWeb.API.FallbackController

  def index(conn, _params) do
    results =
      SmartContractView.list(%{page: conn.params["page"] || 1, page_size: conn.assigns.page_size})

    data =
      JSONAPI.Serializer.serialize(SmartContractView, results.entries, conn, %{
        total_page: results.total_pages,
        current_page: results.page_number
      })

    json(conn, data)
  end
end
