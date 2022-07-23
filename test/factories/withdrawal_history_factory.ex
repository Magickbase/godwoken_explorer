defmodule GodwokenExplorer.WithdrawalHistoryFactory do
  alias GodwokenExplorer.WithdrawalHistory
  alias Decimal, as: D

  defmacro __using__(_opts) do
    quote do
      def withdrawal_history_factory do
        %WithdrawalHistory{
          l2_script_hash: "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
          amount: D.new(10_000_000_000),
          block_hash: "0x07aafde68ea70169bb54cf76b44496d8f5deba5ac89cb1ddc20d10646ddfc09f",
          block_number: 68738,
          owner_lock_hash: "0x66db0f8f6b0ac8b4e92fdfcef8d04a3251a118ccae0ff436957e2c646f083ebd",
          udt_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
          udt_id: 1,
          layer1_block_number: 5_744_914,
          layer1_output_index: 0,
          layer1_tx_hash: "0x41876f5c3ea0d96219c42ea5b4e6cedba61c59fa39bf163765a302f6e43c3847",
          timestamp: ~U[2021-12-03 22:39:39.585000Z],
          state: :pending,
          capacity: D.new(10_000_000_000)
        }
      end
    end
  end
end
