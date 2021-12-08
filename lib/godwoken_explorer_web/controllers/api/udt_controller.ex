defmodule GodwokenExplorerWeb.API.UDTController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{UDT, UDTView, Repo}

  plug JSONAPI.QueryParser, view: UDTView

  # fields[udt]=id,name,symbol,supply,holders,type,short_address
  def index(conn, params) do
    results = UDTView.list(conn.assigns[:page] || 1)
    data = JSONAPI.Serializer.serialize(UDTView, results.entries, conn, %{total_page: results.total_pages, current_page: results.page_number} )
    json(conn, data)
  end

  def show(conn, %{"id" => id} = params) do
    case Repo.get(UDT, id) do
      nil -> %{
        error_code: 404,
        message: "not found"
      }
      udt = %UDT{} ->
        data = JSONAPI.Serializer.serialize(UDTView, udt, conn)
        json(conn, data)
    end
  end
end
