defmodule GodwokenExplorer.PolyjuiceCreatorFactory do
  alias GodwokenExplorer.PolyjuiceCreator

  defmacro __using__(_opts) do
    quote do
      def polyjuice_creator_factory do
        %PolyjuiceCreator{
          code_hash: "0x636b89329db092883883ab5256e435ccabeee07b52091a78be22179636affce8",
          script_args: "40d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b01000000",
          hash_type: "type",
          transaction: build(:polyjuice_creator_tx)
        }
      end
    end
  end
end
