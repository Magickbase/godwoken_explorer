defmodule GodwokenExplorerWeb.API.TransactionController do
  use GodwokenExplorerWeb, :controller
  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]
  alias GodwokenExplorer.{Transaction, Repo}

  def index(conn, params) do
    result = Transaction.list_by_account_id(params["account_id"])
    |> Repo.paginate(page: params["page"])
    parsed_result = result.entries
    |> Enum.map(fn record ->
      stringify_and_unix_maps(record)
    end)

    json(
      conn,
      %{
        page: result.page_number,
        total_count: result.total_entries,
        txs: parsed_result
      }
    )
  end

  def show(conn, %{"hash" => "0x" <> _} = params) do
    tx = Transaction.find_by_hash(params["hash"])
    result = if map_size(tx) == 0 do
      %{
        error_code: 404,
        message: "not found"
      }
    else
      %{
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
      } |> stringify_and_unix_maps()
    end

    json(
      conn,
      result
    )
  end

  def show(conn, params) do
    json(
      conn,
      %{message: "Oops! An invalid Txn hash has been entered: #{params['hash']}"}
    )
  end

end
