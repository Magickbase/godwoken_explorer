defmodule GodwokenExplorerWeb.API.RPC.BlockView do
  use GodwokenExplorerWeb, :view

  alias GodwokenExplorerWeb.API.RPC.RPCView

  def render("getblocknobytime.json", %{block_number: block_number}) do
    data = %{
      "blockNumber" => to_string(block_number)
    }

    RPCView.render("show.json", data: data)
  end

  def render("error.json", %{error: error}) do
    RPCView.render("error.json", error: error)
  end
end
