defmodule GodwokenExplorer.AccountUDTFactory do
  alias GodwokenExplorer.AccountUDT
  alias GodwokenExplorer.Chain.Hash

  defmacro __using__(_opts) do
    quote do
      def account_udt_factory do
        %AccountUDT{
          address_hash: address_hash(),
          token_contract_address_hash: address_hash()
        }
      end

      def address_hash do
        {:ok, address_hash} =
          "address_hash"
          |> sequence(& &1)
          |> Hash.Address.cast()

        if to_string(address_hash) == "0x0000000000000000000000000000000000000000" do
          address_hash()
        else
          address_hash
        end
      end
    end
  end
end
