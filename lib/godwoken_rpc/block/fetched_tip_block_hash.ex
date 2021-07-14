defmodule GodwokenRPC.Block.FetchedTipBlockHash do

  def request do
    GodwokenRPC.request(%{id: 2, method: "gw_get_tip_block_hash"})
  end
end
