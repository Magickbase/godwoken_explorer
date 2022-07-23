defmodule GodwokenExplorer.DepositHistoryFactory do
  alias GodwokenExplorer.DepositHistory
  alias Decimal, as: D

  defmacro __using__(_opts) do
    quote do
      def deposit_history_factory do
        %DepositHistory{
          amount: D.new(40_000_000_000),
          capacity: D.new(40_000_000_000),
          ckb_lock_hash: "0xe6c7befcbf4697f1a7f8f04ffb8de71f5304826af7bfce3e4d396483e935820a",
          layer1_block_number: 5_744_914,
          layer1_output_index: 0,
          layer1_tx_hash: "0x41876f5c3ea0d96219c42ea5b4e6cedba61c59fa39bf163765a302f6e43c3847",
          script_hash: "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
          timestamp: ~U[2021-12-02 22:39:39.585000Z],
          udt_id: 1
        }
      end
    end
  end
end
