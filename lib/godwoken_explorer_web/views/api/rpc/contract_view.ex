defmodule GodwokenExplorerWeb.API.RPC.ContractView do
  use GodwokenExplorerWeb, :view

  alias GodwokenExplorerWeb.API.RPC.RPCView

  def render("getabi.json", %{abi: abi}) do
    RPCView.render("show.json", data: Jason.encode!(abi))
  end

  def render("getsourcecode.json", %{contract: contract}) do
    RPCView.render("show.json",
      data: %{sourcecode: contract.source_code, abi: Jason.encode!(contract.abi)}
    )
  end
end
