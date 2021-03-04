defmodule GodwokenRPC.CKBIndexer.FetchedGlobalState do
  def request do
    state_validator_lock = Application.get_env(:godwoken_explorer, :state_validator_lock)

    GodwokenRPC.request(%{id: 2, method: "get_cells", params: [%{script: state_validator_lock, script_type: "lock"}, "desc", "0x1"]})
  end
end
