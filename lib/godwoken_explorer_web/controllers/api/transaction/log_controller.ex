defmodule GodwokenExplorerWeb.API.Transaction.LogController do
  use GodwokenExplorerWeb, :controller

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.{LogView, Chain}

  action_fallback(GodwokenExplorerWeb.API.FallbackController)

  plug JSONAPI.QueryParser, view: LogView

  def index(conn, %{"hash" => "0x" <> _} = params) do
    case Chain.string_to_transaction_hash(params["hash"]) do
      {:ok, hash} ->
        results = LogView.list_by_tx_hash(hash, conn.params["page"] || 1, conn.assigns.page_size)

        data =
          JSONAPI.Serializer.serialize(
            LogView,
            results.entries |> Enum.map(&stringify_and_unix_maps(&1)),
            conn,
            %{
              total_page: results.total_pages,
              current_page: results.page_number
            }
          )

        json(conn, data)

      :error ->
        {:error, :address_format}
    end
  end

  def index(_conn, _) do
    {:error, :not_found}
  end
end
