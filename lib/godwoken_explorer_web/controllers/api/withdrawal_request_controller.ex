defmodule GodwokenExplorerWeb.API.WithdrawalRequestController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Account, WithdrawalRequestView}

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    data =
      case Account.search( String.downcase(params["eth_address"])) do
        %Account{script_hash: script_hash} ->
          results = WithdrawalRequestView.list_by_script_hash(script_hash, conn.params["page"] || 1)
          JSONAPI.Serializer.serialize(WithdrawalRequestView, results.entries, conn, %{total_page: results.total_pages, current_page: results.page_number} )
        nil ->
            %{
              error_code: 404,
              message: "account not found"
            }
      end

    json(conn, data)
  end

  def index(conn, _) do
    json(conn, %{
        error_code: 400,
        message: "bad request"
      })
  end
end
