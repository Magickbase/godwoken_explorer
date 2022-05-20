defmodule GodwokenExplorerWeb.API.RPC.AccountController do
  use GodwokenExplorerWeb, :controller

  def eth_get_balance(conn, params) do
    json(conn, %{foo: :bar})
  end
end
