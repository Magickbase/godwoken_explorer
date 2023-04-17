defmodule GodwokenExplorer.DailyStatFactory do
  alias GodwokenExplorer.DailyStat
  alias Decimal, as: D

  defmacro __using__(_opts) do
    quote do
      def daily_stat_factory do
        %DailyStat{
          avg_block_size: 384,
          avg_block_time: 30.03,
          avg_gas_used: D.new(10000),
          avg_gas_limit: D.new(100_000),
          date: Date.utc_today(),
          erc20_transfer_count: 1031,
          total_block_count: 2875,
          total_txn: 4366
        }
      end
    end
  end
end
