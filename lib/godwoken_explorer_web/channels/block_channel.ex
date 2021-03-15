defmodule GodwokenExplorerWeb.BlockChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Block

  intercept([
    "bind_l1_block",
    "update_status"
  ])

  def join("blocks:" <> block_number, _params, socket) do
    block = Block.find_by_number_or_hash(block_number)

    result =
      stringify_and_unix_maps(%{
        hash: block.hash,
        number: block.number,
        l1_block: block.layer1_block_number,
        tx_hash: block.layer1_tx_hash,
        finalize_state: block.status,
        tx_count: block.transaction_count,
        aggregator: block.aggregator_id,
        timestamp: block.timestamp
      })

    {:ok, result, assign(socket, :block_number, block_number)}
  end

  def handle_out(
        "bind_l1_block",
        %{l1_block_number: l1_block_number, l1_tx_hash: l1_tx_hash},
        socket
      ) do
    push(socket, "bind_l1_block", %{
      l1_block_number: l1_block_number,
      l1_tx_hash: l1_tx_hash
    })

    {:noreply, socket}
  end

  def handle_out("update_status", %{status: status}, socket) do
    push(socket, "update_status", %{
      status: status
    })

    {:noreply, socket}
  end
end
