defmodule GodwokenExplorer.CurrentUDTBalanceFactory do
  alias GodwokenExplorer.Account.CurrentUDTBalance

  defmacro __using__(_opts) do
    quote do
      def current_udt_balance_factory do
        %CurrentUDTBalance{
          address_hash: address_hash(),
          token_contract_address_hash: address_hash(),
          block_number: 1
        }
      end
    end
  end
end
