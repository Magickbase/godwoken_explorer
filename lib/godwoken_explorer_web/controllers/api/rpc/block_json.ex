defmodule GodwokenExplorerWeb.API.RPC.BlockJSON do
  alias GodwokenExplorerWeb.API.RPC.RPCJSON

  def render("getblocknobytime.json", %{block_number: block_number}) do
    data = %{
      "blockNumber" => to_string(block_number)
    }

    RPCJSON.render("show.json", %{data: data})
  end

  def render("error.json", %{error: error}) do
    RPCJSON.render("error.json", %{error: error})
  end
end
