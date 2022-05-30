defmodule GodwokenRPC.Account.FetchedBalance do
  import GodwokenRPC.Util, only: [number_to_hex: 1]
  import GodwokenRPC, only: [quantity_to_integer: 1]

  def from_response(%{id: id, result: fetched_balance_quantity}, id_to_params)
      when is_map(id_to_params) do
    %{
      eth_address: eth_address,
      udt_id: udt_id,
      account_id: account_id,
      udt_script_hash: udt_script_hash
    } = Map.fetch!(id_to_params, id)

    {:ok,
     %{
       account_id: account_id,
       address_hash: eth_address,
       udt_id: udt_id,
       udt_script_hash: udt_script_hash,
       value: quantity_to_integer(fetched_balance_quantity)
     }}
  end

  def from_response(%{id: id, error: %{code: code, message: message} = error}, id_to_params)
      when is_integer(code) and is_binary(message) and is_map(id_to_params) do
    %{registry_address: registry_address, udt_id: udt_id} = Map.fetch!(id_to_params, id)

    annotated_error = Map.put(error, :data, %{registry_address: registry_address, udt_id: udt_id})

    {:error, annotated_error}
  end

  def request(%{id: id, registry_address: registry_address, udt_id: udt_id}) do
    GodwokenRPC.request(%{
      id: id,
      method: "gw_get_balance",
      params: [registry_address, number_to_hex(udt_id)]
    })
  end
end
