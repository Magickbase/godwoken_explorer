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

      def udt_factory do
        id = sequence(:id, & &1)

        %UDT{
          id: id,
          script_hash: block_hash(),
          type: :native,
          name: sequence("UDT", &"UDT#{&1}"),
          bridge_account_id: id
        }
      end
    end
  end
end
