defmodule GodwokenExplorer.AccountUDTFactory do
  alias GodwokenExplorer.AccountUDT

  defmacro __using__(_opts) do
    quote do
      def account_udt_factory do
        %AccountUDT{
          address_hash: address_hash(),
          token_contract_address_hash: address_hash()
        }
      end
    end
  end
end
