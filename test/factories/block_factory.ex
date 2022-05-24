defmodule GodwokenExplorer.BlockFactory do
  alias GodwokenExplorer.Block

  defmacro __using__(_opts) do
    quote do
      def block_factory do
        %Block{
          number: block_number(),
          hash: block_hash(),
          parent_hash: block_hash(),
          size: Enum.random(1..100_000),
          aggregator: build(:user),
          gas_limit: Enum.random(1..100_000),
          gas_used: Enum.random(1..100_000),
          timestamp: DateTime.utc_now(),
          status: :finalized
        }
      end
    end
  end
end
