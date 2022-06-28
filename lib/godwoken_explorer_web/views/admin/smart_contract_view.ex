defmodule GodwokenExplorerWeb.Admin.SmartContractView do
  use GodwokenExplorerWeb, :view

  import Torch.TableView
  import Torch.FilterView

  def deployment_tx_hash(conn) do
    smart_contract = conn.assigns[:smart_contract]
    if smart_contract, do: to_string(smart_contract.deployment_tx_hash)
  end
end
