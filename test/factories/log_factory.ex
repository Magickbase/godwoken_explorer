defmodule GodwokenExplorer.LogFactory do
  alias GodwokenExplorer.Log

  defmacro __using__(_opts) do
    quote do
      def log_factory do
        block = build(:block)

        %Log{
          address_hash: address_hash(),
          block: block,
          block_number: block.number,
          data: data(:log_data),
          first_topic: nil,
          fourth_topic: nil,
          index: sequence("log_index", & &1),
          second_topic: nil,
          third_topic: nil,
          transaction_hash: build(:transaction).eth_hash
        }
      end
    end
  end
end
