defmodule GodwokenRPC.Transaction.FetchedTransaction do
 def request(tx_hash) do
    GodwokenRPC.request(%{
      id: 1,
      method: "gw_get_transaction",
      params: [tx_hash]
    })
  end
end
