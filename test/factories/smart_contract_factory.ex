defmodule GodwokenExplorer.SmartContractFactory do
  alias GodwokenExplorer.SmartContract

  defmacro __using__(_opts) do
    quote do
      def smart_contract_factory do
        contract = build(:polyjuice_contract_account)

        %SmartContract{
          account: contract,
          address_hash: contract.eth_address,
          abi: Jason.decode!(File.read!(Path.join(["test/support", "erc20_abi.json"]))),
          contract_source_code: "abc",
          name: sequence("UDT", &"Contract#{&1}")
        }
      end

      def proxy_contract_factory do
        contract = build(:polyjuice_contract_account)

        %SmartContract{
          account: contract,
          address_hash: contract.eth_address,
          abi: Jason.decode!(File.read!(Path.join(["test/support", "proxy_abi.json"]))),
          contract_source_code: "abc",
          name: sequence("UDT", &"Contract#{&1}")
        }
      end
    end
  end
end
