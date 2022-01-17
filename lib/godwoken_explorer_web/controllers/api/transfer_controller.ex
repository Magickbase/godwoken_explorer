defmodule GodwokenExplorerWeb.API.TransferController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Transaction, Account, Repo}

  def index(conn, %{"eth_address" => "0x" <> _, "udt_address" => "0x" <> _} = params) do
    %Account{id: account_id, eth_address: eth_address} = Repo.get_by(Account, eth_address: String.downcase(params["eth_address"]))

    %Account{id: udt_account_id} =
      Repo.get_by(Account, short_address: String.downcase(params["udt_address"]))

    results =
      Transaction.account_transactions_data(
        %{account_id: account_id, eth_address: eth_address, udt_account_id: udt_account_id},
        conn.params["page"] || 1
      )

    json(conn, results)
  end

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    %Account{id: account_id, eth_address: eth_address} = Repo.get_by(Account, eth_address: String.downcase(params["eth_address"]))

    results =
      Transaction.account_transactions_data(
        %{account_id: account_id, eth_address: eth_address, erc20: true},
        conn.params["page"] || 1
      )

    json(conn, results)
  end


  def index(conn, %{"udt_address" => "0x" <> _} = params) do
    %Account{id: account_id} =
      Repo.get_by(Account, short_address: String.downcase(params["udt_address"]))

    results =
      Transaction.account_transactions_data(
        %{udt_account_id: account_id},
        conn.params["page"] || 1
      )

    json(conn, results)
  end
end
