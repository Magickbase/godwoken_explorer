defmodule GodwokenExplorer.AddressFactory do
  alias GodwokenExplorer.Address

  defmacro __using__(_opts) do
    quote do
      def address_factory do
        %Address{
          eth_address: address_hash(),
          bit_alias: "address.bit"
        }
      end
    end
  end
end
