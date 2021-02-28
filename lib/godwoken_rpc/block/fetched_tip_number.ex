defmodule GodwokenRPC.Block.FetchedTipNumber do

  def request do
    GodwokenRPC.request(%{id: 2, method: "gw_getTipBlockNumber"})
  end
end
