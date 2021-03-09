defmodule GodwokenExplorerWeb.API.AccountController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Repo, Account}

  def show(conn, params) do
    result = case Repo.get(Account, params["id"]) do
      %Account{} -> Account.find_by_id(params["id"])
      nil ->  %{
        error_code: 404,
        message: "not found"
      }
    end
    json(
      conn,
      result
    )
  end
end
