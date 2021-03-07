defmodule GodwokenRPC.CKBIndexer.FetchedCells do
  def request(script, script_type, order \\ "desc", limit \\ "0x64") do
    GodwokenRPC.request(%{id: 2, method: "get_cells", params: [%{script: script, script_type: script_type}, order, limit]})
  end
end
