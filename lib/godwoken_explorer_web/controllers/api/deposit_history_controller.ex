defmodule GodwokenExplorerWeb.API.DepositHistoryController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Account, Chain, DepositHistoryView, Repo}

  action_fallback GodwokenExplorerWeb.API.FallbackController

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(params["eth_address"]),
         %Account{script_hash: script_hash} <- Repo.get_by(Account, eth_address: address_hash) do
      results = DepositHistoryView.list_by_script_hash(script_hash, conn.params["page"] || 1)

      data =
        JSONAPI.Serializer.serialize(DepositHistoryView, results.entries, conn, %{
          total_page: results.total_pages,
          current_page: results.page_number
        })

      json(conn, data)
    else
      nil ->
        {:error, :not_found}

      :error ->
        {:error, :address_format}
    end
  end

  def index(_conn, _) do
    {:error, :not_found}
  end
end
