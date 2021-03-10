defmodule GodwokenExplorerWeb.API.AccountController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Repo, Account}

  def show(conn, %{"id" => id}) do
    result =
      case Repo.get(Account, id) do
        %Account{} ->
          Account.find_by_id(id)
          |> account_to_view()

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

  defp account_to_view(account) do
    account = %{account | ckb: balance_to_view(account.ckb, 8)}

    account =
      with udt_list when not is_nil(udt_list) <- Kernel.get_in(account, [:user, :udt_list]) do
        Kernel.put_in(
          account,
          [:user, :udt_list],
          udt_list
          |> Enum.map(fn udt ->
            %{udt | balance: balance_to_view(udt.balance, udt.decimal)}
          end)
        )
      end

    account
  end

  defp balance_to_view(balance, decimal) do
    {val, _} = Integer.parse(balance)
    (val / :math.pow(10, decimal)) |> :erlang.float_to_binary(decimals: decimal)
  rescue
    _ ->
      balance
  end
end
