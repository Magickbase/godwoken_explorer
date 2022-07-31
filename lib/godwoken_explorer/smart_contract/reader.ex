defmodule GodwokenExplorer.SmartContract.Reader do
  def query_contracts(requests, abi) do
    json_rpc_named_arguments = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    GodwokenRPC.execute_contract_functions(requests, abi, json_rpc_named_arguments, true)
  end

  def query_contract(contract_address, abi, functions, leave_error_as_map) do
    query_contract_inner(contract_address, abi, functions, nil, nil, leave_error_as_map)
  end

  def query_contract(contract_address, from, abi, functions, leave_error_as_map) do
    query_contract_inner(contract_address, abi, functions, nil, from, leave_error_as_map)
  end

  def query_contract_by_block_number(
        contract_address,
        abi,
        functions,
        block_number,
        leave_error_as_map \\ false
      ) do
    query_contract_inner(contract_address, abi, functions, block_number, nil, leave_error_as_map)
  end

  defp query_contract_inner(
         contract_address,
         abi,
         functions,
         block_number,
         from,
         leave_error_as_map
       ) do
    requests =
      functions
      |> Enum.map(fn {method_id, args} ->
        %{
          contract_address: contract_address,
          from: from,
          method_id: method_id,
          args: args,
          block_number: block_number
        }
      end)

    requests
    |> query_contracts(abi, [], leave_error_as_map)
    |> Enum.zip(requests)
    |> Enum.into(%{}, fn {response, request} ->
      {request.method_id, response}
    end)
  end

  def query_contracts(requests, abi, opts \\ []) do
    json_rpc_named_arguments =
      Keyword.get(opts, :json_rpc_named_arguments) ||
        Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    GodwokenRPC.execute_contract_functions(requests, abi, json_rpc_named_arguments)
  end

  def query_contracts(requests, abi, [], leave_error_as_map) do
    json_rpc_named_arguments = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    GodwokenRPC.execute_contract_functions(
      requests,
      abi,
      json_rpc_named_arguments,
      leave_error_as_map
    )
  end
end
