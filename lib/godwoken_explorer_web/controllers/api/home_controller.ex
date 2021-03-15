defmodule GodwokenExplorerWeb.API.HomeController do
  use GodwokenExplorerWeb, :controller
  alias GodwokenExplorer.{Block, Transaction, Chain}

  def index(conn, _params) do
    blocks = Block.latest_10_records()
    transactions = Transaction.latest_10_records()

    result = Chain.home_api_data(blocks, transactions)

    json(conn, result)
  end
end
