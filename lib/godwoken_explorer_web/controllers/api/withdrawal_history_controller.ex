defmodule GodwokenExplorerWeb.API.WithdrawalHistoryController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Account, Chain, Repo, WithdrawalHistoryView}

  action_fallback(GodwokenExplorerWeb.API.FallbackController)

  def index(conn, %{"owner_lock_hash" => "0x" <> _} = params) do
    results =
      WithdrawalHistoryView.find_by_owner_lock_hash(
        String.downcase(params["owner_lock_hash"]),
        conn.params["state"],
        conn.params["page"] || 1
      )

    data =
      JSONAPI.Serializer.serialize(WithdrawalHistoryView, results.entries, conn, %{
        total_page: results.total_pages,
        current_page: results.page_number
      })

    json(conn, data)
  end

  def index(conn, %{"l2_script_hash" => "0x" <> _} = params) do
    results =
      WithdrawalHistoryView.find_by_l2_script_hash(
        String.downcase(params["l2_script_hash"]),
        conn.params["state"],
        conn.params["page"] || 1
      )

    data =
      JSONAPI.Serializer.serialize(WithdrawalHistoryView, results.entries, conn, %{
        total_page: results.total_pages,
        current_page: results.page_number
      })

    json(conn, data)
  end

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    with {:ok, address_hash} <-
           Chain.string_to_address_hash(params["eth_address"]),
         %Account{script_hash: script_hash} <-
           Repo.get_by(Account, eth_address: address_hash) do
      results =
        WithdrawalHistoryView.find_by_l2_script_hash(
          script_hash,
          conn.params["state"],
          conn.params["page"] || 1
        )

      data =
        JSONAPI.Serializer.serialize(WithdrawalHistoryView, results.entries, conn, %{
          total_page: results.total_pages,
          current_page: results.page_number
        })

      json(conn, data)
    else
      nil ->
        {:error, :not_found}
    end
  end

  def index(_conn, _) do
    {:error, :bad_request}
  end
end
