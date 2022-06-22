defmodule GodwokenExplorerWeb.API.PolyVersionController do
  use GodwokenExplorerWeb, :controller

  def index(conn, _params) do
    result = GodwokenExplorer.Chain.Cache.PolyVersion.get_version()

    json(conn, result)
  end
end
