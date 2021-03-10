defmodule GodwokenExplorerWeb.HomeChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  intercept(["home"])

  def join("home:refresh", _params, socket) do
    {:ok, %{}, socket}
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
