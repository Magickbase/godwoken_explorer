defmodule GodwokenRPC.Block.ByNumber do
  def request(%{id: id, number: number}) do
    GodwokenRPC.request(%{id: id, method: "gw_get_block_by_number", params: [number]})
  end
end
