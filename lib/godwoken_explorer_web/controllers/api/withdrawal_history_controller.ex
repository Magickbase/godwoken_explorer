defmodule GodwokenExplorerWeb.API.WithdrawalHistoryController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{WithdrawalHistoryView, Account}

  def index(conn, %{"owner_lock_hash" => "0x" <> _} = params) do
    results = WithdrawalHistoryView.find_by_owner_lock_hash(String.downcase(params["owner_lock_hash"]), conn.assigns[:page] || 1)
    data = JSONAPI.Serializer.serialize(GodwokenExplorer.WithdrawalHistoryView, results.entries, conn, %{total_page: results.total_pages, current_page: results.page_number} )
    json(conn, data)
  end

  def index(conn, _) do
    json(conn, %{
        error_code: 400,
        message: "bad request"
      })
  end
end
