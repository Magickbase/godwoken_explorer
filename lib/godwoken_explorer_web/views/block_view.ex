defmodule GodwokenExplorer.BlockView do
  use JSONAPI.View, type: "block"

  import Ecto.Query, only: [from: 2]
  import GodwokenRPC.Util, only: [utc_to_unix: 1]

  alias GodwokenExplorer.{Block, Repo}

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

  def finalize_state(block, _conn) do
    block.status
  end

  def id(%Block{number: number}), do: number

  def tx_count(block, _conn) do
    block.transaction_count
  end

  def miner_hash(block, _conn) do
    block.producer_address
  end

  def timestamp(block, _conn) do
    utc_to_unix(block.inserted_at)
  end

  def list(page, page_size) do
    from(
      b in Block,
      join: a in assoc(b, :account),
      preload: [account: a],
      order_by: [desc: :number]
    )
    |> Repo.paginate(page: page, page_size: page_size)
  end
end
