defmodule GodwokenExplorerWeb.API.UDTController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.UDTView

  # fields[udt]=id,name,symbol,supply,holders,type,short_address
  def index(conn, params) do
    results = UDTView.list(conn.assigns[:page] || 1)
    data = JSONAPI.Serializer.serialize(UDTView, results.entries, conn, %{total_page: results.total_pages, current_page: results.page_number} )
    json(conn, data)
  end
end
