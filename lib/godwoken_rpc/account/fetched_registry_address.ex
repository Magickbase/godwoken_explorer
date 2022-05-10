defmodule GodwokenRPC.Account.FetchedRegistryAddress do
  import GodwokenRPC.Util, only: [parse_registry_address: 1]

  def request(%{id: id, script_hash: script_hash}) do
    eth_addr_reg_id = Application.get_env(:godwoken_explorer, :eth_addr_reg_id)

    GodwokenRPC.request(%{
      id: id,
      method: "gw_get_registry_address_by_script_hash",
      params: [script_hash, eth_addr_reg_id]
    })
  end

  def from_response(%{id: id, result: registry_address}, id_to_params)
      when is_map(id_to_params) do
    %{script_hash: script_hash} = Map.fetch!(id_to_params, id)

    {:ok,
     %{
       script_hash: script_hash,
       registry_address: parse_registry_address(registry_address)
     }}
  end

  def from_response(%{id: id, error: %{code: code, message: message} = error}, id_to_params)
      when is_integer(code) and is_binary(message) and is_map(id_to_params) do
    %{script_hash: script_hash} = Map.fetch!(id_to_params, id)

    annotated_error = Map.put(error, :data, %{script_hash: script_hash})

    {:error, annotated_error}
  end
end
