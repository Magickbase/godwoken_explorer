defmodule GodwokenExplorerWeb.API.FallbackController do
  use GodwokenExplorerWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(GodwokenExplorerWeb.ErrorView)
    |> render("404.json")
  end

  def call(conn, {:error, :address_format}) do
    conn
    |> put_status(:bad_request)
    |> put_view(GodwokenExplorerWeb.ErrorView)
    |> render("400.json")
  end
end
