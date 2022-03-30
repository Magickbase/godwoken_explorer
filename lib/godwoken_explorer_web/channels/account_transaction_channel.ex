defmodule GodwokenExplorerWeb.AccountTransactionChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  alias GodwokenExplorer.{Account, Transaction, Repo}

  intercept(["refresh"])

  def join("account_transactions:" <> account_id, _params, socket) do
    with %Account{id: account_id, type: type} = account <- Repo.get(Account, account_id) do
      results = Transaction.account_transactions_data(%{type: type, account: account}, 1)

      {:ok, results, assign(socket, :account_id, account_id)}
    end
  end

  def handle_out(
        "refresh",
        %{
          page: page,
          total_count: total_count,
          txs: txs
        },
        socket
      ) do
    push(socket, "refresh", %{
      page: page,
      total_count: total_count,
      txs: txs
    })

    {:noreply, socket}
  end
end
