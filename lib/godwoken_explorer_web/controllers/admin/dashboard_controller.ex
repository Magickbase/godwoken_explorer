defmodule GodwokenExplorerWeb.Admin.DashboardController do
  use GodwokenExplorerWeb, :controller

  plug(:put_root_layout, {GodwokenExplorerWeb.LayoutView, "torch.html"})
  plug(:put_layout, false)

  def index(conn, _) do
    render(conn, "index.html")
  end

  def flush_poly_version_cache(conn, _key) do
    ConCache.delete(:poly_version, :version)

    conn
    |> put_flash(:success, "flush cache successfully")
    |> redirect(to: Routes.admin_dashboard_path(conn, :index))
  end
end
