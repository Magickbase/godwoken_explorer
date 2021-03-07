defmodule GodwokenRPC.CKBIndexer.FetchedTransactions do
  def request(script, script_type, order \\ "desc", limit \\ "0x64", filter \\ %{}) do
    GodwokenRPC.request(%{id: 2, method: "get_transactions", params:
    [
      %{script: script, script_type: script_type, filter: filter}, order, limit
    ]})
  end
end
