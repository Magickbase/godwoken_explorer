defmodule GodwokenRPC.CKBIndexer.FetchedTransactions do
  def request(%{script: script, script_type: script_type, order: order, limit: limit, filter: filter}) do
    GodwokenRPC.request(%{id: 2, method: "get_transactions", params:
    [
      %{script: script, script_type: script_type, filter: filter}, order, limit
    ]})
  end
end
