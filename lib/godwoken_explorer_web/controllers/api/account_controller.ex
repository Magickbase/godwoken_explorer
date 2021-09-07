defmodule GodwokenExplorerWeb.API.AccountController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Repo, Account}

  def show(conn, %{"id" => id}) when is_integer(id) do
    result =
      case Repo.get(Account, id) do
        %Account{} ->
          id
          |> Account.find_by_id()
          |> Account.account_to_view()

        nil ->
          %{
            error_code: 404,
            message: "not found"
          }
      end

    json(
      conn,
      result
    )
  end

  def show(conn, %{"id" => eth_address}) do
    result =
      case Account.search(eth_address) do
        %Account{id: id} ->
          id
          |> Account.find_by_id()
          |> Account.account_to_view()

        nil ->
          %{
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
