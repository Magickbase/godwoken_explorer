defmodule GodwokenRPC.CKBIndexer.FetchedBlock do
  import GodwokenRPC.Util, only: [number_to_hex: 1]

  def from_response(%{id: id, result: result}, id_to_params)
      when is_map(id_to_params) do
    %{block_number: block_number} = Map.fetch!(id_to_params, id)

    {:ok,
     %{
       block_number: block_number,
       block: result
     }}
  end

  def from_response(%{id: id, error: %{code: code, message: message} = error}, id_to_params)
      when is_integer(code) and is_binary(message) and is_map(id_to_params) do
    %{block_number: block_number} = Map.fetch!(id_to_params, id)

    annotated_error = Map.put(error, :data, %{block_number: block_number})

    {:error, annotated_error}
  end

  def request(%{id: id, block_number: block_number}) do
    GodwokenRPC.request(%{
      id: id,
      method: "get_block_by_number",
      params: [number_to_hex(block_number)]
    })
  end
end
