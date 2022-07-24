defmodule GodwokenRPC.Transaction.GetGwTxByEthTx do
  def request(eth_tx_hash) do
    GodwokenRPC.request(%{
      id: 0,
      method: "poly_getGwTxHashByEthTxHash",
      params: [eth_tx_hash]
    })
  end
end
