defmodule GodwokenRPC.Account.FetchedScript do
  def request(%{id: id, script_hash: script_hash}) do
    GodwokenRPC.request(%{id: id, method: "gw_get_script", params: [script_hash]})
  end

  def from_response(%{id: id, result: script}, id_to_params)
      when is_map(id_to_params) do
    %{script_hash: script_hash, account_id: account_id} = Map.fetch!(id_to_params, id)

    {:ok,
     %{
       script_hash: script_hash,
       account_id: account_id,
       script: script
     }}
  end

  def from_response(%{id: id, error: %{code: code, message: message} = error}, id_to_params)
      when is_integer(code) and is_binary(message) and is_map(id_to_params) do
    %{script_hash: script_hash, account_id: account_id} = Map.fetch!(id_to_params, id)

    annotated_error = Map.put(error, :data, %{script_hash: script_hash, account_id: account_id})

    {:error, annotated_error}
  end
end
