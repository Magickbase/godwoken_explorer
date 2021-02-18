defmodule GodwokenRPC.Block.ByHash do
  def request(%{id: id, hash: hash}) do
    GodwokenRPC.request(%{id: id, method: "gw_getBlock", params: [hash]})
  end
end
