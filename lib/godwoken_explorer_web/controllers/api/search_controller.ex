defmodule GodwokenExplorerWeb.API.SearchController do
  use GodwokenExplorerWeb, :controller
  action_fallback GodwokenExplorerWeb.API.FallbackController

  alias GodwokenExplorer.{Account, Block, Chain, Transaction, UDT}

  def index(conn, %{"keyword" => query}) do
    query
    |> String.trim()
    |> Chain.from_param()
    |> case do
      {:ok, item} ->
        render_search_results(conn, item)

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def index(_conn, _) do
    {:error, :not_found}
  end

  defp render_search_results(conn, %Account{} = item) do
    id =
      case item.type do
        :eth_user -> item.eth_address
        :polyjuice_contract -> item.eth_address
        _ -> item.script_hash
      end

    json(conn, %{type: "account", id: id})
  end

  defp render_search_results(conn, %Block{} = item) do
    json(conn, %{type: "block", id: item.number})
  end

  defp render_search_results(conn, %Transaction{} = item) do
    json(conn, %{type: "transaction", id: item.eth_hash || item.hash})
  end

  defp render_search_results(conn, %UDT{} = item) do
    json(conn, %{type: "udt", id: item.id})
  end
end
