defmodule GodwokenExplorerWeb.API.AccountController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Repo, Account}

  def show(conn, %{"id" => "0x" <> _} = params) do
    downcase_id = params["id"] |> String.downcase()

    result =
      case Account.search(downcase_id) do
        %Account{id: id} ->
          Account.sync_special_udt_balance(id)
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

  def show(conn, %{"id" => id}) do
    result =
      case Repo.get(Account, id) do
        %Account{} ->
          Account.sync_special_udt_balance(id)
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
