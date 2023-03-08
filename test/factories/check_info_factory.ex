defmodule GodwokenExplorer.CheckInfoFactory do
  alias GodwokenExplorer.CheckInfo

  defmacro __using__(_opts) do
    quote do
      def check_info_factory do
        %CheckInfo{
          block_hash: block_hash(),
          tip_block_number: block_number(),
          type: "main_deposit"
        }
      end
    end
  end
end
