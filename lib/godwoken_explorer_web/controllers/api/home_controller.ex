defmodule GodwokenExplorerWeb.API.HomeController do
  use GodwokenExplorerWeb, :controller
  alias GodwokenExplorer.{Block, Transaction, Chain}

  def index(conn, _params) do
    blocks = Block.latest_10_records()
    transactions = Transaction.latest_10_records()
    account_count = Chain.account_estimated_count()
    block_count = Chain.block_estimated_count()
    tx_count = Chain.transaction_estimated_count()

    json(
      conn,
      %{
        statistic:  %{
          block_count: block_count,
          tx_count: tx_count,
          tps: "10",
          account_count: account_count
        },
        block_list: blocks,
        tx_list: transactions
      }
    )
  end
end
