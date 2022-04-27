defmodule GodwokenExplorerWeb.API.BlockController do
  use GodwokenExplorerWeb, :controller

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.Block
  alias GodwokenExplorer.BlockView

  plug JSONAPI.QueryParser, view: BlockView

  def index(conn, _params) do
    results = BlockView.list(conn.params["page"] || 1, conn.assigns.page_size)

    data =
      JSONAPI.Serializer.serialize(BlockView, results.entries, conn, %{
        total_page: results.total_pages,
        current_page: results.page_number
      })

    json(conn, data)
  end

  def show(conn, params) do
    block = Block.find_by_number_or_hash(params["id"])

    result =
      if is_nil(block) do
        %{
          error_code: 404,
          message: "not found"
        }
      else
        %{
          hash: block.hash,
          number: block.number,
          l1_block: block.layer1_block_number,
          l1_tx_hash: block.layer1_tx_hash,
          finalize_state: block.status,
          tx_count: block.transaction_count,
          miner_hash: Block.miner_hash(block),
          timestamp: block.timestamp,
          gas_limit: block.gas_limit,
          gas_used: block.gas_used,
          size: block.size,
          parent_hash: block.parent_hash,
          logs_bloom: block.logs_bloom
        }
        |> stringify_and_unix_maps()
      end

    json(
      conn,
      result
    )
  end
end
