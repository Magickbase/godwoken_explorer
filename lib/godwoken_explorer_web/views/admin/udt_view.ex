defmodule GodwokenExplorerWeb.Admin.UDTView do
  use GodwokenExplorerWeb, :view

  import Torch.TableView
  import Torch.FilterView

  def type_script_value(conn, key) do
    if conn.assigns[:udt] do
      Map.get(conn.assigns[:udt].type_script, key, "")
    else
      ""
    end
  end
end
