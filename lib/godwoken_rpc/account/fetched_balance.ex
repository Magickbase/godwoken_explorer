defmodule GodwokenRPC.Account.FetchedBalance do
  import GodwokenRPC.Util, only: [number_to_hex: 1]

  def request(%{short_address: short_address, udt_id: udt_id}) do
    GodwokenRPC.request(%{
      id: "0",
      method: "gw_get_balance",
      params: [short_address, number_to_hex(udt_id)]
    })
  end
end
