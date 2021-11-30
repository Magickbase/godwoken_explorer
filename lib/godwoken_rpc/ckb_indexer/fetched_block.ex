defmodule GodwokenRPC.CKBIndexer.FetchedBlock do
  import GodwokenRPC.Util, only: [number_to_hex: 1]

  def request(block_number) do
    GodwokenRPC.request(%{
      id: 1,
      method: "get_block_by_number",
      params: [number_to_hex(block_number)]
    })
  end
end
