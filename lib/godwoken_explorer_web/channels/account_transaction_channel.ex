defmodule GodwokenExplorerWeb.AccountTransactionChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  alias GodwokenExplorer.Transaction

  intercept(["refresh"])

  def join("account_transactions:" <> account_id, _params, socket) do
    results = Transaction.account_transactions_data(account_id, 1)

    {:ok, results, assign(socket, :account_id, account_id)}
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
