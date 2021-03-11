defmodule GodwokenExplorerWeb.HomeChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  alias GodwokenExplorer.Block

  intercept(["home"])

  def join("home:refresh", _params, socket) do
    blocks = Block.latest_10_records()

    {:ok, %{block_list: blocks}, socket}
  end

  @spec handle_out(
          <<_::56>>,
          %{:block_list => any, :statistic => any, :tx_list => any, optional(any) => any},
          Phoenix.Socket.t()
        ) :: {:noreply, Phoenix.Socket.t()}
  def handle_out("refresh", %{block_list: block_list, tx_list: tx_list, statistic: statistic}, socket) do
    push(socket, "refresh", %{
      block_list: block_list,
      tx_list: tx_list,
      statistic: statistic
    })

    {:noreply, socket}
  end
end
