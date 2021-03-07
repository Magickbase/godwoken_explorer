defmodule GodwokenRPC.CKBIndexer.FetchedTransaction do
  def request(tx_hash) do
    GodwokenRPC.request(%{id: 2, method: "get_transaction", params: [tx_hash]})
  end
end
