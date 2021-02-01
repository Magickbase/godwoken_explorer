defmodule GodwokenExplorerWeb.BlockChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  intercept(["new_block"])

  def join("blocks:new_block", _params, socket) do
    {:ok, %{}, socket}
  end

  def handle_out("new_block", %{block: block}, socket) do
    push(socket, "new_block", %{
      block: block
    })

    {:noreply, socket}
  end
end
