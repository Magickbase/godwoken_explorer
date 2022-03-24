defmodule GodwokenExplorer.BlockFactory do
  alias GodwokenExplorer.Block

  defmacro __using__(_opts) do
    quote do
      def block_factory do
        %Block{
          hash: :crypto.strong_rand_bytes(32)  |> Base.encode16(case: :lower),
          parent_hash: :crypto.strong_rand_bytes(32)  |> Base.encode16(case: :lower),
          number: 14,
          timestamp: ~U[2021-10-31 05:39:38.000000Z],
          status: :finalized,
          aggregator_id: 0,
          transaction_count: 1,
          gas_limit: Enum.random(1..100_000),
          gas_used: Enum.random(1..100_000),
          size: Enum.random(1..100_000),
          logs_bloom:
            "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          layer1_block_number: Enum.random(0..1_000_000),
          layer1_tx_hash: :crypto.strong_rand_bytes(32)  |> Base.encode16(case: :lower)
        }
      end
    end
  end
end
