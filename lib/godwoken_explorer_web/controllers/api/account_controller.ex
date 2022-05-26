defmodule GodwokenExplorerWeb.API.AccountController do
  use GodwokenExplorerWeb, :controller

  action_fallback GodwokenExplorerWeb.API.FallbackController

  alias GodwokenExplorer.{Account, Chain}
  alias GodwokenExplorer.Counters.{AddressTokenTransfersCounter, AddressTransactionsCounter}

  def show(conn, %{"id" => "0x" <> _} = params) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(params["id"]) do
      case Account.search(address_hash) do
        %Account{id: id} = account ->
          fetch_transfer_and_transaction_count(account)

          result =
            id
            |> Account.find_by_id()
            |> Account.account_to_view()

          json(
            conn,
            result
          )

        nil ->
          result = Account.non_create_account_info(address_hash)

          json(
            conn,
            result
          )
      end
    else
      :error ->
        {:error, :address_format}
    end
  end

  defp fetch_transfer_and_transaction_count(account) do
    Task.async(fn ->
      AddressTokenTransfersCounter.fetch(account)
    end)

    Task.async(fn ->
      AddressTransactionsCounter.fetch(account)
    end)
  end
end
