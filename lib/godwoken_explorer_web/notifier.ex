defmodule GodwokenExplorerWeb.Notifier do
  @moduledoc """
  Responds to events by sending appropriate channel updates to front-end.
  """

  alias GodwokenExplorerWeb.Endpoint

  def handle_event({:chain_event, :home, :realtime, data}) do
    broadcast_block(data)
  end

  def handle_event(_), do: nil

  defp broadcast_block(data) do
    Endpoint.broadcast("home:refresh", "refresh", data)
  end
end
