defmodule GodwokenRPC.Web3.EthCall do
  import GodwokenRPC.Util, only: [number_to_hex: 1]

  def request(params) do
    IO.puts(inspect(params))
    GodwokenRPC.request(%{
      id: "0",
      method: "eth_call",
      params: [params, "latest"]
    })
  end
end
