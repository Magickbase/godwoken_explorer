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
          producer_address: address_hash(),
          gas_limit: Enum.random(1..100_000),
          gas_used: Enum.random(1..100_000),
          timestamp:
            DateTime.utc_now()
            |> DateTime.to_unix(:millisecond)
            |> Kernel.*(1000)
            |> DateTime.from_unix!(:microsecond),
          status: :finalized
        }
      end
    end
  end
end
