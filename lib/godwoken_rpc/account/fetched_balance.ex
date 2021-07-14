defmodule GodwokenRPC.Account.FetchedBalance do
  def request(%{account_id: account_id, udt_id: udt_id}) do
    GodwokenRPC.request(%{id: account_id, method: "gw_get_balance", params: [account_id, udt_id]})
  end
end
