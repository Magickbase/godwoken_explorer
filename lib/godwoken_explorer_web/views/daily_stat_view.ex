defmodule GodwokenExplorer.DailyStatView do
  use JSONAPI.View, type: "daily_stat"

  import Ecto.Query, only: [from: 2]

  def fields do
    [
      :id,
      :date,
      :total_txn,
      :avg_block_time,
      :avg_block_size,
      :total_block_count,
      :erc20_transfer_count,
      :avg_gas_limit,
      :avg_gas_used
    ]
  end
end
