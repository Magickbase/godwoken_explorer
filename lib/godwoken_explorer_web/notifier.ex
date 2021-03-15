defmodule GodwokenExplorerWeb.Notifier do
  @moduledoc """
  Responds to events by sending appropriate channel updates to front-end.
  """

  alias GodwokenExplorerWeb.Endpoint

  def handle_event({:chain_event, :home, :realtime, data}) do
    broadcast_home(data)
  end

  def handle_event({:chain_event, :blocks, :realtime, block}) do
    broadcast_block(block)
  end

  def handle_event({:chain_event, :transactions, :realtime, tx}) do
    broadcast_transaction(tx)
  end

  def handle_event(_), do: nil

  defp broadcast_home(data) do
    Endpoint.broadcast("home:refresh", "refresh", data)
  end

  defp broadcast_block(%{number: number, l1_block_number: l1_block_number, l1_tx_hash: l1_tx_hash, status: status}) do
    Endpoint.broadcast("blocks:#{number}", "refresh", %{l1_block_number: l1_block_number, l1_tx_hash: l1_tx_hash, status: status})
  end

  defp broadcast_transaction(%{tx_hash: tx_hash, l1_block_number: l1_block_number, status: status}) do
    Endpoint.broadcast("transactions:#{tx_hash}", "refresh", %{l1_block_number: l1_block_number, status: status})
  end
end
