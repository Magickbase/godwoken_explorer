defmodule GodwokenExplorer.ContractMethodFactory do
  alias GodwokenExplorer.ContractMethod

  defmacro __using__(_opts) do
    quote do
      def contract_method_factory do
        %ContractMethod{
          abi: %{
            "constant" => false,
            "inputs" => [
              %{"name" => "_to", "type" => "address"},
              %{"name" => "_value", "type" => "uint256"}
            ],
            "name" => "transfer",
            "outputs" => [%{"name" => "", "type" => "bool"}],
            "payable" => false,
            "stateMutability" => "nonpayable",
            "type" => "function"
          },
          identifier: <<169, 5, 156, 187>>,
          type: "function"
        }
      end
    end
  end
end
