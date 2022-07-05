defmodule GodwokenRPC.Account.FetchedScriptHash do
  import GodwokenRPC.Util, only: [number_to_hex: 1]

  def request(%{id: id, account_id: account_id}) do
    GodwokenRPC.request(%{
      id: id,
      method: "gw_get_script_hash",
      params: [number_to_hex(account_id)]
    })
  end

  def request(%{id: id, short_address: short_address}) do
    GodwokenRPC.request(%{
      id: id,
      method: "gw_get_script_hash_by_short_address",
      params: [short_address]
    })
  end

  def from_response(%{id: id, result: script_hash}, id_to_params)
      when is_map(id_to_params) do
    %{account_id: account_id} = Map.fetch!(id_to_params, id)

    {:ok,
     %{
       id: account_id,
       script_hash: script_hash
     }}
  end

  def from_response(%{id: id, error: %{code: code, message: message} = error}, id_to_params)
      when is_integer(code) and is_binary(message) and is_map(id_to_params) do
    %{account_id: account_id} = Map.fetch!(id_to_params, id)

    annotated_error = Map.put(error, :data, %{id: account_id})

    {:error, annotated_error}
  end
end
