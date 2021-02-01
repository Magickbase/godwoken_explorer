defmodule GodwokenExplorerWeb.PageController do
  use GodwokenExplorerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
