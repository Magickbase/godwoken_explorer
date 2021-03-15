defmodule GodwokenExplorerWeb.BlockChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  intercept([
    "bind_l1_block",
    "update_status"
    ])
  def join("blocks:" <> block_number, _params, socket) do
    {:ok, %{}, assign(socket, :block_number, block_number)}
  end

  def handle_out("bind_l1_block", %{l1_block_number: l1_block_number, l1_tx_hash: l1_tx_hash}, socket) do
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
