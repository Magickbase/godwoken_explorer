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

  def handle_event(_), do: nil

  defp broadcast_home(data) do
    Endpoint.broadcast("home:refresh", "refresh", data)
  end

  defp broadcast_block(%{number: number, l1_block_number: l1_block_number, l1_tx_hash: l1_tx_hash}) do
    Endpoint.broadcast("blocks:#{number}", "bind_l1_lock", %{l1_block_number: l1_block_number, l1_tx_hash: l1_tx_hash})
  end
  defp broadcast_block(%{number: number, status: status}) do
    Endpoint.broadcast("blocks:#{number}", "update_status", %{status: status})
  end

end
