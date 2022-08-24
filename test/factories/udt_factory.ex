defmodule GodwokenExplorer.UDTFactory do
  alias GodwokenExplorer.UDT

  defmacro __using__(_opts) do
    quote do
      def ckb_udt_factory do
        %UDT{
          id: 1,
          name: "pCKB",
          decimal: 18,
          script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
          type: :bridge,
          supply: Enum.random(1_000_000_000..1_000_000_000),
          bridge_account_id: 247
        }
      end

      def ckb_native_udt_factory do
        %UDT{
          id: 247,
          script_hash: block_hash(),
          type: :native,
          eth_type: :erc20,
          name: sequence("UDT", &"UDT#{&1}"),
          contract_address_hash: address_hash(),
          decimal: 18,
          supply: Enum.random(1_000_000_000..1_000_000_000)
        }
      end

      def native_udt_factory do
        id = sequence(:id, & &1, start_at: 1000)

        %UDT{
          id: id,
          script_hash: block_hash(),
          type: :native,
          eth_type: :erc20,
          name: sequence("UDT", &"UDT#{&1}"),
          contract_address_hash: address_hash(),
          decimal: 18,
          supply: Enum.random(1_000_000_000..1_000_000_000)
        }
      end
    end
  end
end
