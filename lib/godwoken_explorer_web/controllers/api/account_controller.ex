defmodule GodwokenExplorerWeb.API.AccountController do
  use GodwokenExplorerWeb, :controller

  action_fallback GodwokenExplorerWeb.API.FallbackController

  alias GodwokenExplorer.{Repo, Account}

  def show(conn, %{"id" => "0x" <> _} = params) do
    downcase_id = params["id"] |> String.downcase()

    case Account |> Repo.get_by(eth_address: downcase_id) do
      %Account{id: id} ->
        result =
          id
          |> Account.find_by_id()
          |> Account.account_to_view()

        json(
          conn,
          result
        )

      nil ->
        {:error, :not_found}
    end
  end

  def show(conn, %{"id" => id}) do
    case id |> Integer.parse() do
      {num, ""} ->
        case Repo.get(Account, num) do
          %Account{} ->
            result =
              id
              |> Account.find_by_id()
              |> Account.account_to_view()

            json(
              conn,
              result
            )

          nil ->
            {:error, :not_found}
        end
      _ ->
        {:error, :not_found}
    end
  end
end
