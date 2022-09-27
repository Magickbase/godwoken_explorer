defmodule GodwokenExplorer.DepositHistoryFactory do
  alias GodwokenExplorer.DepositHistory
  alias Decimal, as: D

  defmacro __using__(_opts) do
    quote do
      def deposit_history_factory do
        %DepositHistory{
          amount: D.new(40_000_000_000),
          capacity: D.new(40_000_000_000),
          ckb_lock_hash: transaction_hash(),
          layer1_block_number: block_number(),
          layer1_output_index: 0,
          layer1_tx_hash: transaction_hash(),
          script_hash: transaction_hash(),
          timestamp: ~U[2021-12-02 22:39:39.585000Z],
          udt_id: 1
        }
      end
    end
  end
end
