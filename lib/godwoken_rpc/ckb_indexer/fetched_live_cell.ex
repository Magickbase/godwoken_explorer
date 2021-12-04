defmodule GodwokenRPC.CKBIndexer.FetchedLiveCell do
  import GodwokenRPC.Util, only: [number_to_hex: 1]

  def request(index, tx_hash) do
    GodwokenRPC.request(%{id: 1, method: "get_live_cell", params: [%{index: number_to_hex(index), tx_hash: tx_hash}, true]})
  end
end
