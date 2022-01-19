defmodule GodwokenExplorerWeb.API.FallbackController do
  use GodwokenExplorerWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(GodwokenExplorerWeb.ErrorView)
    |> render("404.json")
  end
end
