defmodule GodwokenExplorerWeb.API.RPC.AccountView do
  use GodwokenExplorerWeb, :view

  alias GodwokenExplorerWeb.API.RPC.RPCView

  def render("balance.json", %{addresses: [address]}) do
    RPCView.render("show.json", data: address[:balance])
  end

  def render("balance.json", assigns) do
    render("balancemulti.json", assigns)
  end

  def render("balancemulti.json", %{addresses: addresses}) do
    RPCView.render("show.json", data: addresses)
  end

  def render("error.json", assigns) do
    RPCView.render("error.json", assigns)
  end
end
