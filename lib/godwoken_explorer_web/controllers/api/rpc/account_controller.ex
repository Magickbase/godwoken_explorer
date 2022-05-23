defmodule GodwokenExplorerWeb.API.RPC.AccountController do
  use GodwokenExplorerWeb, :controller

  def balance(conn, params) do
  end

  def balancemulti(conn, params) do
  end

  def txlist(conn, params) do
  end

  def tokentx(conn, params) do
  end

  defp fetch_address(params) do
    {:address_param, Map.fetch(params, "address")}
  end
end
