defmodule GodwokenExplorer.WithdrawalHistoryFactory do
  alias GodwokenExplorer.WithdrawalHistory
  alias Decimal, as: D

  defmacro __using__(_opts) do
    quote do
      def withdrawal_history_factory do
        %WithdrawalHistory{
          l2_script_hash: transaction_hash(),
          amount: Enum.random(100_000..200_000) |> D.new(),
          block_hash: transaction_hash(),
          block_number: block_number(),
          owner_lock_hash: transaction_hash(),
          udt_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
          udt_id: 1,
          layer1_block_number: block_number(),
          layer1_output_index: 0,
          layer1_tx_hash: transaction_hash(),
          timestamp: ~U[2021-12-03 22:39:39.585000Z],
          state: :pending,
          capacity: Enum.random(10_000_000_000..20_000_000_000) |> D.new()
        }
      end
    end
  end
end
