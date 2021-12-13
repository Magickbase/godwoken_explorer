defmodule GodwokenExplorerWeb.API.UDTController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.UDTView

  plug JSONAPI.QueryParser, view: UDTView

  # fields[udt]=id,name,symbol,supply,holders,type,short_address
  def index(conn, _params) do
    results = UDTView.list(conn.params["type"], conn.params["page"] || 1)
    data = JSONAPI.Serializer.serialize(UDTView, results.entries, conn, %{total_page: results.total_pages, current_page: results.page_number} )
    json(conn, data)
  end


  def show(conn, %{"id" => id} = _params) do
    result =
      case UDTView.get_udt(id) do
        nil -> %{
          error_code: 404,
          message: "not found"
        }
        udt = %{name: _name} ->
          JSONAPI.Serializer.serialize(UDTView, udt, conn)
      end
    json(conn, result)
  end
end
