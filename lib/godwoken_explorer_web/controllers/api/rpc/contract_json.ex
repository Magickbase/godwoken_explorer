defmodule GodwokenExplorerWeb.API.RPC.ContractJSON do
  alias GodwokenExplorerWeb.API.RPC.RPCJSON

  def render("getabi.json", %{abi: abi}) do
    RPCJSON.render("show.json", %{data: Jason.encode!(abi)})
  end

  def render("getsourcecode.json", %{contract: contract}) do
    RPCJSON.render(
      "show.json",
      %{
        data: [
          %{"SourceCode" => contract.contract_source_code, "ABI" => Jason.encode!(contract.abi)}
        ]
      }
    )
  end

  def render("error.json", assigns) do
    RPCJSON.render("error.json", assigns)
  end
end
