defmodule GodwokenExplorerWeb.AccountChannel do
  @moduledoc """
  Establishes pub/sub channel for live updates of block events.
  """
  use GodwokenExplorerWeb, :channel

  alias GodwokenExplorer.Account

  intercept(["refresh"])

  def join("accounts:" <> account_id, _params, socket) do
    if account_id == "null" do
      {:error, %{reason: "no account id"}}
    else
      result =
        account_id
        |> Account.find_by_id()
        |> Account.account_to_view()

      {:ok, result, assign(socket, :account_id, account_id)}
    end
  end

  def handle_out(
        "refresh",
        account,
        socket
      ) do
    push(socket, "refresh", account)

    {:noreply, socket}
  end
end
