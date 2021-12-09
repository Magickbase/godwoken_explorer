defmodule GodwokenRPC.Web3.EthCall do
  def request(params) do
    GodwokenRPC.request(%{
      id: "0",
      method: "eth_call",
      params: [params, "latest"]
    })
  end
end
