defmodule GodwokenExplorerWeb.API.TransferController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Transaction, Account, Repo}

  action_fallback GodwokenExplorerWeb.API.FallbackController

  def index(conn, %{"eth_address" => "0x" <> _, "udt_address" => "0x" <> _} = params) do
      with %Account{id: account_id, eth_address: eth_address} <-
             Repo.get_by(Account, eth_address: String.downcase(params["eth_address"])),
           %Account{id: udt_account_id} =
             Repo.get_by(Account, short_address: String.downcase(params["udt_address"])) do
        results =
          Transaction.account_transactions_data(
            %{account_id: account_id, eth_address: eth_address, udt_account_id: udt_account_id},
            conn.params["page"] || 1
          )

        json(conn, results)
      else
        _ ->
          raise {:error, :not_found}
      end
  end

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    case Repo.get_by(Account, eth_address: String.downcase(params["eth_address"])) do
      %Account{id: account_id, eth_address: eth_address} ->
        results =
          Transaction.account_transactions_data(
            %{account_id: account_id, eth_address: eth_address, erc20: true},
            conn.params["page"] || 1
          )

        json(conn, results)
      nil ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"udt_address" => "0x" <> _} = params) do
    case Repo.get_by(Account, short_address: String.downcase(params["udt_address"])) do
      %Account{id: account_id} ->
        results =
          Transaction.account_transactions_data(
            %{udt_account_id: account_id},
            conn.params["page"] || 1
          )

        json(conn, results)

      nil ->
        {:error, :not_found}
    end
  end
end
