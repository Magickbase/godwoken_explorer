defmodule GodwokenRPC.FetchedAccountID do

  def request(%{id: id, script_hash: script_hash}) do
    GodwokenRPC.request(%{id: id, method: "gw_getAccountIdByScriptHash", params: [script_hash]})
  end
end
