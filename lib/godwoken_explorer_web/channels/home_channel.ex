defmodule GodwokenExplorerWeb.HomeChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  alias GodwokenExplorer.{Block, Transaction, Chain}

  intercept(["home"])

  def join("home:refresh", _params, socket) do
    blocks = Block.latest_10_records()
    txs = Transaction.latest_10_records()
    account_count = Chain.account_estimated_count()
    tx_count = Chain.transaction_estimated_count()
    tps = Block.transactions_count_per_second()

    statistic = %{
      block_count: (blocks |> List.first() |> Map.get(:number) |> String.to_integer()) + 1,
      tx_count: tx_count|> Integer.to_string(),
      tps: tps |> Float.to_string(),
      account_count: account_count |> Integer.to_string()
    }

    {:ok, %{block_list: blocks, tx_list: txs, statistic: statistic}, socket}
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
