defmodule GodwokenExplorer.SmartContract.Reader do
  def query_contracts(requests, abi) do
    json_rpc_named_arguments =
      Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    GodwokenRPC.execute_contract_functions(requests, abi, json_rpc_named_arguments, true)
  end
end
