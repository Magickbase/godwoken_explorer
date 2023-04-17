defmodule GodwokenExplorerWeb.API.FallbackController do
  use GodwokenExplorerWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(GodwokenExplorerWeb.API.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :eth_hash, eth_hash}) do
    conn
    |> put_status(:bad_request)
    |> put_view(GodwokenExplorerWeb.API.ErrorJSON)
    |> render(:"10001", %{eth_hash: eth_hash})
  end

  def call(conn, {:error, :address_format}) do
    conn
    |> put_status(:bad_request)
    |> put_view(GodwokenExplorerWeb.API.ErrorJSON)
    |> render(:"400")
  end

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> put_view(GodwokenExplorerWeb.API.ErrorJSON)
    |> render(:"400")
  end
end
