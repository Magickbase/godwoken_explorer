defmodule GodwokenExplorerWeb.TransactionChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Transaction

  intercept(["refresh"])

  def join("transactions:" <> tx_hash, _params, socket) do
    tx = Transaction.find_by_hash(tx_hash)

    result =
      stringify_and_unix_maps(%{
          hash: tx.hash,
          timestamp: tx.timestamp,
          finalize_state: tx.status,
          l2_block: tx.l2_block_number,
          l1_block: tx.l1_block_number,
          from: tx.from,
          to: tx.to,
          nonce: tx.nonce,
          args: tx.args,
          type: tx.type,
          gas_price: tx |> Map.get(:gas_price, Decimal.new(0)),
          fee: tx |> Map.get(:fee, Decimal.new(0))
      })

    {:ok, result, assign(socket, :tx_hash, tx_hash)}
  end

  def handle_out(
        "refresh",
        %{l1_block_number: l1_block_number, status: status},
        socket
      ) do
    push(socket, "refresh", %{
      l1_block: l1_block_number,
      finalize_state: status
    })

    {:noreply, socket}
  end
end
