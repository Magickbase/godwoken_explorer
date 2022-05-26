defmodule GodwokenExplorer.PolyjuiceFactory do
  alias GodwokenExplorer.Polyjuice

  defmacro __using__(_opts) do
    quote do
      def polyjuice_factory do
        %Polyjuice{
          created_contract_address_hash: nil,
          gas_limit: Enum.random(21_000..100_000),
          gas_price: Enum.random(10..99) * 1_000_000_00,
          gas_used: Enum.random(10_000..21_000),
          input: transaction_input(),
          input_size: 4,
          is_create: false,
          status: :succeed,
          transaction_index: sequence("transaction_index", & &1),
          transaction: build(:transaction),
          value: Enum.random(1..100_000)
        }
      end
    end
  end
end
