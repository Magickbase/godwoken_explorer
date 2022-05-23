defmodule GodwokenExplorer.UDTFactory do
  alias GodwokenExplorer.UDT

  defmacro __using__(_opts) do
    quote do
      def ckb_udt_factory do
        %UDT{
          id: 1,
          name: "CKB",
          decimal: 8,
          script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
          type: :bridge,
          bridge_account_id: 247
        }
      end
    end
  end
end
