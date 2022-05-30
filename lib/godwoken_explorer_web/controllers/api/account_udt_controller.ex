defmodule GodwokenExplorerWeb.API.AccountUDTController do
  use GodwokenExplorerWeb, :controller

  action_fallback GodwokenExplorerWeb.API.FallbackController

  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Account.CurrentUDTBalance

  def index(conn, %{"udt_id" => udt_id}) do
    with %UDT{} <- Repo.get(UDT, udt_id) do
      result =
        CurrentUDTBalance.sort_holder_list(
          udt_id,
          %{page: conn.params["page"] || 1, page_size: conn.assigns.page_size}
        )

      json(
        conn,
        result
      )
    else
      _ ->
        {:error, :not_found}
    end
  end
end
