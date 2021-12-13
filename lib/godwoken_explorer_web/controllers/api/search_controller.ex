defmodule GodwokenExplorerWeb.API.SearchController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Repo, Account, Block, Transaction, PendingTransaction, UDT}

  def index(conn, %{"keyword" => "0x" <> _} = params) do
    downcase_keyword = String.downcase(params["keyword"])

    result =
      cond do
        (block = Repo.get_by(Block, hash: downcase_keyword)) != nil ->
          %{type: "block", id: block.number}

        (transaction = Repo.get_by(Transaction, hash: downcase_keyword)) != nil ->
          %{type: "transaction", id: transaction.hash}

        (pending_tx = PendingTransaction.find_by_hash(downcase_keyword)) != nil ->
          %{type: "transaction", id: pending_tx.hash}

        (account = Account.search(downcase_keyword)) != nil ->
          %{type: "account", id: account.id}

        true ->
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

  def index(conn, %{"keyword" => keyword}) do
    result =
      case keyword |> String.replace(",", "") |> Integer.parse() do
        {num, ""} ->
          case Repo.get_by(Account, id: num) do
            %Account{id: id} ->
              %{type: "account", id: id}

            nil ->
              %{
                error_code: 404,
                message: "not found"
              }
          end

        _ ->
          cond do
            (udt = UDT.find_by_name_or_token(keyword)) != nil ->
              %{type: "udt", id: udt.id}
            true ->
              %{
                error_code: 404,
                message: "not found"
              }
          end
      end

    json(
      conn,
      result
    )
  end
end
