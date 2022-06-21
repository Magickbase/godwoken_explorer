defmodule GodwokenExplorerWeb.API.DepositWithdrawalController do
  use GodwokenExplorerWeb, :controller

  action_fallback GodwokenExplorerWeb.API.FallbackController

  alias GodwokenExplorer.{Account, Block, Chain, DepositWithdrawalView, Repo, UDT}

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(params["eth_address"]),
         %Account{script_hash: script_hash} <- Repo.get_by(Account, eth_address: address_hash) do
      data = DepositWithdrawalView.list_by_script_hash(script_hash, conn.params["page"] || 1)
      json(conn, data)
    else
      nil ->
        data = %{
          page: 1,
          total_count: 0,
          data: []
        }

        json(conn, data)

      :error ->
        {:error, :bad_request}
    end
  end

  def index(conn, %{"udt_id" => _udt_id} = params) do
    case Repo.get(UDT, params["udt_id"]) do
      %UDT{id: id} ->
        data = DepositWithdrawalView.list_by_udt_id(id, conn.params["page"] || 1)
        json(conn, data)

      nil ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"block_number" => _block_number} = params) do
    case Repo.get_by(Block, number: params["block_number"]) do
      %Block{number: number} ->
        data = DepositWithdrawalView.list_by_block_number(number, conn.params["page"] || 1)
        json(conn, data)

      nil ->
        {:error, :not_found}
    end
  end

  def index(_conn, _) do
    {:error, :not_found}
  end
end
