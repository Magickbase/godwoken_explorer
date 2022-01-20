defmodule GodwokenExplorerWeb.API.DepositWithdrawalController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Account, DepositWithdrawalView, UDT, Repo, Block}

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

  def index(conn, %{"udt_id" => _udt_id} = params) do
    data =
      case Repo.get(UDT, params["udt_id"]) do
        %UDT{id: id} ->
          DepositWithdrawalView.list_by_udt_id(id, conn.params["page"] || 1)
        nil ->
            %{
              error_code: 404,
              message: "not found"
            }
      end

    json(conn, data)
  end

  def index(conn, %{"block_number" => _block_number} = params) do
    data =
      case Repo.get_by(Block, number: params["block_number"]) do
        %Block{number: number} ->
          DepositWithdrawalView.list_by_block_number(number, conn.params["page"] || 1)
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
