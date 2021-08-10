defmodule GodwokenRPC.Block.ByNumber do
  import GodwokenRPC.Util, only: [number_to_hex: 1]

  def request(%{id: id, number: number}) do
    GodwokenRPC.request(%{id: id, method: "gw_get_block_by_number", params: [number_to_hex(number)]})
  end
end
