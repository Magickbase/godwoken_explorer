defmodule GodwokenRPC.Account.FetchedAccountID do

  def request(%{script_hash: script_hash}) do
    GodwokenRPC.request(%{id: "2", method: "gw_get_account_id_by_script_hash", params: [script_hash]})
  end
end
