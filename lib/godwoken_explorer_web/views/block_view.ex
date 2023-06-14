defmodule GodwokenExplorer.BlockView do
  use JSONAPI.View, type: "block"

  import Ecto.Query, only: [from: 2]
  import GodwokenRPC.Util, only: [utc_to_unix: 1]

  alias GodwokenExplorer.{Block, Repo}
  alias GodwokenExplorer.Chain.Cache.BlockCount

  @block_capped_limit 500_000

  def fields do
    [
      :hash,
      :number,
      :finalize_state,
      :tx_count,
      :miner_hash,
      :timestamp,
      :gas_limit,
      :gas_used
    ]
  end

  def hash(block, _conn) do
    to_string(block.hash)
  end

  def finalize_state(block, _conn) do
    block.status
  end

  def id(%Block{number: number}), do: number

  def tx_count(block, _conn) do
    block.transaction_count
  end

  def miner_hash(block, _conn) do
    to_string(block.producer_address)
  end

  def timestamp(block, _conn) do
    utc_to_unix(block.timestamp)
  end

  def list(page, page_size) do
    paging_options =
      if BlockCount.estimated_count() > @block_capped_limit do
        [total_entries: @block_capped_limit]
      else
        []
      end

    from(
      b in Block,
      order_by: [desc: :number]
    )
    |> Repo.paginate(
      page: page,
      page_size: page_size,
      options: paging_options
    )
  end
end
