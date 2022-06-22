defmodule GodwokenRPC.Web3.FetchedPolyVersion do
  def request() do
    GodwokenRPC.request(%{
      id: "0",
      method: "poly_version",
      params: []
    })
  end
end
