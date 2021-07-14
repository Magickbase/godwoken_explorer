defmodule GodwokenRPC.Block.ByHash do
  def request(%{id: id, hash: hash}) do
    GodwokenRPC.request(%{id: id, method: "gw_get_block", params: [hash]})
  end
end
