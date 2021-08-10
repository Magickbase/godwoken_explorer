defmodule GodwokenRPC.Account.FetchedNonce do
  import GodwokenRPC.Util, only: [number_to_hex: 1]

  def request(%{account_id: account_id}) do
    GodwokenRPC.request(%{id: account_id, method: "gw_get_nonce", params: [number_to_hex(account_id)]})
  end
end
