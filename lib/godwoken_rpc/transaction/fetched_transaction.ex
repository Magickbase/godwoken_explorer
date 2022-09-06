defmodule GodwokenRPC.Transaction.FetchedTransaction do
  def request(%{id: id, gw_tx_hash: gw_tx_hash}) do
    GodwokenRPC.request(%{
      id: id,
      method: "gw_get_transaction",
      params: [gw_tx_hash]
    })
  end

  def from_response(%{id: _id, result: transaction}, id_to_params)
      when is_map(id_to_params) do
    {:ok, transaction}
  end

  def from_response(%{id: id, error: %{code: code, message: message} = error}, id_to_params)
      when is_integer(code) and is_binary(message) and is_map(id_to_params) do
    %{gw_tx_hash: tx_hash} = Map.fetch!(id_to_params, id)

    annotated_error = Map.put(error, :data, %{gw_tx_hash: tx_hash})

    {:error, annotated_error}
  end
end
