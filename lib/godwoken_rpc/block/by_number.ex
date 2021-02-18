defmodule GodwokenRPC.Block.ByNumber do
  def request(%{id: id, number: number}) do
    GodwokenRPC.request(%{id: id, method: "gw_getBlockByNumber", params: [number]})
  end
end
