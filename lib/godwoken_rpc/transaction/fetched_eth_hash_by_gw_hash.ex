defmodule GodwokenRPC.Transaction.FetchedEthHashByGwHash do
  def request(%{id: id, gw_tx_hash: gw_tx_hash}) do
    GodwokenRPC.request(%{
      id: id,
      method: "poly_getEthTxHashByGwTxHash",
      params: [gw_tx_hash]
    })
  end

  def from_response(%{id: id, result: eth_hash}, id_to_params)
      when is_map(id_to_params) do
    %{
      gw_tx_hash: gw_tx_hash
    } = Map.fetch!(id_to_params, id)

    {:ok,
     %{
       gw_tx_hash: gw_tx_hash,
       eth_hash: eth_hash
     }}
  end

  def from_response(%{id: id, error: %{code: code, message: message} = error}, id_to_params)
      when is_integer(code) and is_binary(message) and is_map(id_to_params) do
    %{gw_tx_hash: tx_hash} = Map.fetch!(id_to_params, id)

    annotated_error = Map.put(error, :data, %{gw_tx_hash: tx_hash})

    {:error, annotated_error}
  end
end
