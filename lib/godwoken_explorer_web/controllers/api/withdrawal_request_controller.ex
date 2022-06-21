defmodule GodwokenExplorerWeb.API.WithdrawalRequestController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Account, Chain, Repo, WithdrawalRequestView}

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    data =
      with {:ok, address_hash} <-
             Chain.string_to_address_hash(params["eth_address"]),
           %Account{script_hash: script_hash} <-
             Repo.get_by(Account, eth_address: address_hash) do
        results = WithdrawalRequestView.list_by_script_hash(script_hash, conn.params["page"] || 1)

        JSONAPI.Serializer.serialize(WithdrawalRequestView, results.entries, conn, %{
          total_page: results.total_pages,
          current_page: results.page_number
        })
      else
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
