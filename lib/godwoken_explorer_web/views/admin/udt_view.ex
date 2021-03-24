defmodule GodwokenExplorerWeb.Admin.UDTView do
  use GodwokenExplorerWeb, :view

  import Torch.TableView
  import Torch.FilterView

  def type_script_value(conn, key) do
    udt = conn.assigns[:udt]
    if udt && udt.type_script  do
      Map.get(udt.type_script, key, "")
    else
      ""
    end
  end
end
