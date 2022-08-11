defmodule GodwokenExplorer.UDTBalanceFactory do
  alias GodwokenExplorer.Account.UDTBalance

  defmacro __using__(_opts) do
    quote do
      def udt_balance_factory do
        %UDTBalance{
          address_hash: address_hash(),
          token_contract_address_hash: address_hash(),
          block_number: 1,
          value: Enum.random(1..100_000)
        }
      end
    end
  end
end
