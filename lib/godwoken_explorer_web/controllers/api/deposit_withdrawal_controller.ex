defmodule GodwokenExplorerWeb.API.DepositWithdrawalController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Account, DepositWithdrawalView}

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    data =
      case Account.search(String.downcase(params["eth_address"])) do
        %Account{script_hash: script_hash} ->
          DepositWithdrawalView.list_by_script_hash(script_hash, conn.params["page"] || 1)
        nil ->
            %{
              error_code: 404,
              message: "not found"
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
