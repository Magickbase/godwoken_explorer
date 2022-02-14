defmodule GodwokenExplorerWeb.API.UDTController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{UDTView, Account}

  plug JSONAPI.QueryParser, view: UDTView
  action_fallback GodwokenExplorerWeb.API.FallbackController

  # fields[udt]=id,name,symbol,supply,holders,type,short_address
  def index(conn, _params) do
    results = UDTView.list(conn.params["type"], conn.params["page"] || 1)

    data =
      JSONAPI.Serializer.serialize(UDTView, results.entries, conn, %{
        total_page: results.total_pages,
        current_page: results.page_number
      })

    json(conn, data)
  end

  def show(conn, %{"id" => "0x" <> _} = params) do
    downcase_id = params["id"] |> String.downcase()

    case Account.search(downcase_id) do
      %Account{id: id} ->
        case UDTView.get_udt(id) do
          nil ->
            {:error, :not_found}
          udt = %{name: _name} ->
            result = JSONAPI.Serializer.serialize(UDTView, udt, conn)
            json(conn, result)
        end

      nil ->
        {:error, :not_found}
    end
  end

  def show(conn, %{"id" => id} = _params) do
    case UDTView.get_udt(id) do
      nil ->
        {:error, :not_found}
      udt = %{name: _name} ->
        result = JSONAPI.Serializer.serialize(UDTView, udt, conn)
        json(conn, result)
    end
  end
end
