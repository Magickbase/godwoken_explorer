defmodule GodwokenExplorerWeb.HomeChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  alias GodwokenExplorer.{Block, Transaction, Chain}

  intercept(["refresh"])

  def join("home:refresh", _params, socket) do
    blocks = Block.latest_10_records()
    txs = Transaction.latest_10_records()
    result = Chain.home_api_data(blocks, txs)

    {:ok, result, socket}
  end

  def handle_out("refresh", %{block_list: block_list, tx_list: tx_list, statistic: statistic}, socket) do
    push(socket, "refresh", %{
      block_list: block_list,
      tx_list: tx_list,
      statistic: statistic
    })

    {:noreply, socket}
  end
end
