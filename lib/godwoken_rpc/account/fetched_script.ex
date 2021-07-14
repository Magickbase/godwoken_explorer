defmodule GodwokenRPC.Account.FetchedScript do
  def request(%{script_hash: script_hash}) do
    GodwokenRPC.request(%{id: "2", method: "gw_get_script", params: [script_hash]})
  end
end
