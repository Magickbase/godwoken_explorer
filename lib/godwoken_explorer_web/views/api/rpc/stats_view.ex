defmodule GodwokenExplorerWeb.API.RPC.StatsView do
  use GodwokenExplorerWeb, :view

  alias GodwokenExplorerWeb.API.RPC.RPCView

  def render("tokensupply.json", %{total_supply: token_supply}) do
    RPCView.render("show.json", data: token_supply)
  end

  def render("error.json", assigns) do
    RPCView.render("error.json", assigns)
  end
end
