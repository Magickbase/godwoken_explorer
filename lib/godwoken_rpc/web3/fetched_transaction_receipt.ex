defmodule GodwokenRPC.Web3.FetchedTransactionReceipt do
  def request(tx_hash) do
    GodwokenRPC.request(%{
      id: "0",
      method: "eth_getTransactionReceipt",
      params: [tx_hash]
    })
  end
end
