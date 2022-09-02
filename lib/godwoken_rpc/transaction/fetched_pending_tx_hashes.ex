defmodule GodwokenRPC.Transaction.FetchedPendingTxHashes do
  def request() do
    GodwokenRPC.request(%{
      id: 1,
      method: "gw_get_pending_tx_hashes",
      params: []
    })
  end
end
