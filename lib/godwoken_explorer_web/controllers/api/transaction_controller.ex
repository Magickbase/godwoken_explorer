defmodule GodwokenExplorerWeb.API.TransactionController do
  use GodwokenExplorerWeb, :controller
  alias GodwokenExplorer.{Transaction, Repo}

  def index(conn, params) do
    result = Transaction.list_by_account_id(params["account_id"])
    |> Repo.paginate(page: params["page"])
    json(
      conn,
      %{
        page: result.page_number,
        total_count: result.total_entries,
        txs: result.entries
      }
    )
  end

  def show(conn, %{"hash" => "0x" <> _} = params) do
    tx = Transaction.find_by_hash(params["hash"])
    result = if is_nil(tx) do
      %{
        error_code: 404,
        message: "not found"
      }
    else
      %{
          hash: tx.hash,
          timestamp: tx.timestamp,
          finalize_state: tx.status,
          l2_block: tx.block_number, # block number
          l1_block: tx.block_number, # block number
          from: tx.from,
          to: tx.to,
          nonce: tx.nonce,
          args: tx.args,
          type: tx.type,
          gas_price: tx |> Map.get(:gas_price, 0),
          fee: tx |> Map.get(:fee, 0)
      }
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
