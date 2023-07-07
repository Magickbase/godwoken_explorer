defmodule GodwokenRPC.CKBIndexer.FetchedTip do
  def request do
    GodwokenRPC.request(%{id: 2, method: "get_indexer_tip"})
  end
end
