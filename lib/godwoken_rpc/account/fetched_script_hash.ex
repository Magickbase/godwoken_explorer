defmodule GodwokenRPC.Account.FetchedScriptHash do
  import GodwokenRPC.Util, only: [number_to_hex: 1]

  def request(%{account_id: account_id}) do
    GodwokenRPC.request(%{
      id: account_id,
      method: "gw_get_script_hash",
      params: [number_to_hex(account_id)]
    })
  end

  def request(%{short_address: short_address}) do
    GodwokenRPC.request(%{
      id: "1",
      method: "gw_get_script_hash_by_short_address",
      params: [short_address]
    })
  end
end
