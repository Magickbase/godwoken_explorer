defmodule GodwokenRPC.Account.FetchedScriptHash do
  def request(%{account_id: account_id}) do
    GodwokenRPC.request(%{id: account_id, method: "gw_get_script_hash", params: [account_id]})
  end
end
