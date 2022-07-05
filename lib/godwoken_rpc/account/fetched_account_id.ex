defmodule GodwokenRPC.Account.FetchedAccountID do
  import GodwokenRPC.Util, only: [hex_to_number: 1]

  def from_response(%{id: id, result: result}, id_to_params)
      when result != nil and is_map(id_to_params) do
    %{script_hash: script_hash, script: script} = Map.fetch!(id_to_params, id)

    {:ok,
     %{
       script_hash: script_hash,
       script: script,
       id: result |> hex_to_number()
     }}
  end

  def from_response(%{id: id, result: nil}, id_to_params) when is_map(id_to_params) do
    %{script_hash: script_hash, script: script} = Map.fetch!(id_to_params, id)

    annotated_error =
      Map.put(%{code: 404, message: "account create slow"}, :data, %{
        script_hash: script_hash,
        script: script
      })

    {:error, annotated_error}
  end

  def from_response(%{id: id, error: %{code: code, message: message} = error}, id_to_params)
      when is_integer(code) and is_binary(message) and is_map(id_to_params) do
    %{script_hash: script_hash, script: script} = Map.fetch!(id_to_params, id)

    annotated_error = Map.put(error, :data, %{script_hash: script_hash, script: script})

    {:error, annotated_error}
  end

  def request(%{id: id, script: _script, script_hash: script_hash}) do
    GodwokenRPC.request(%{
      id: id,
      method: "gw_get_account_id_by_script_hash",
      params: [script_hash]
    })
  end
end
