defmodule GodwokenExplorerWeb.API.AccountController do
  use GodwokenExplorerWeb, :controller

  action_fallback GodwokenExplorerWeb.API.FallbackController

  alias GodwokenExplorer.{Account, Chain, Repo}

  def show(conn, %{"id" => "0x" <> _} = params) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(params["id"]) do
      case Repo.get_by(Account, eth_address: address_hash) do
        %Account{id: id} = account ->
          Account.async_fetch_transfer_and_transaction_count(account)

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
        with {:ok, script_hash} <- Chain.string_to_script_hash(params["id"]) do
          case Repo.get_by(Account, script_hash: script_hash) do
            %Account{id: id} = account ->
              Account.async_fetch_transfer_and_transaction_count(account)

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
        else
          :error ->
            {:error, :address_format}
        end
    end
  end
end
