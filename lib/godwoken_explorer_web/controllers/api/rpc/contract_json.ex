defmodule GodwokenExplorerWeb.API.RPC.ContractJSON do
  alias GodwokenExplorerWeb.API.RPC.RPCJSON

  def render("getabi.json", %{abi: abi}) do
    RPCJSON.render("show.json", %{data: Jason.encode!(abi)})
  end

  def render("getsourcecode.json", %{contract: contract}) do
    RPCJSON.render(
      "show.json",
      %{data: %{sourcecode: contract.source_code, abi: Jason.encode!(contract.abi)}}
    )
  end
end
