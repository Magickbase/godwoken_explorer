defmodule GodwokenExplorerWeb.API.RPC.StatsJSON do
  alias GodwokenExplorerWeb.API.RPC.RPCJSON

  def render("tokensupply.json", %{total_supply: token_supply}) do
    RPCJSON.render("show.json", %{data: token_supply})
  end

  def render("error.json", assigns) do
    RPCJSON.render("error.json", assigns)
  end
end
