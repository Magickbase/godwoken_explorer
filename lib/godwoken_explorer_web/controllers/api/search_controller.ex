defmodule GodwokenExplorerWeb.API.SearchController do
  use GodwokenExplorerWeb, :controller
  action_fallback GodwokenExplorerWeb.API.FallbackController

  alias GodwokenExplorer.{Repo, Account, Block, Transaction, PendingTransaction, UDT}

  @max_integer 2_147_483_647
  @block_tx_hash_length 66
  @account_hash_length 42

  def index(conn, %{"keyword" => "0x" <> _} = params) do
    downcase_keyword = String.downcase(params["keyword"])

    cond do
      String.length(downcase_keyword) == @block_tx_hash_length ->
        cond do
          (block = Repo.get_by(Block, hash: downcase_keyword)) != nil ->
            json(conn, %{type: "block", id: block.number})

          (transaction = Repo.get_by(Transaction, hash: downcase_keyword)) != nil ->
            json(conn, %{type: "transaction", id: transaction.hash})

          (pending_tx = PendingTransaction.find_by_hash(downcase_keyword)) != nil ->
            json(conn, %{type: "transaction", id: pending_tx.hash})

          true ->
            {:error, :not_found}
        end

      String.length(downcase_keyword) == @account_hash_length ->
        case Account.search(downcase_keyword) do
          %Account{id: id} ->
            json(conn, %{type: "account", id: id |> Account.display_id() |> elem(0)})

          nil ->
            json(conn, %{type: "account", id: downcase_keyword})
        end

      true ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"keyword" => keyword}) do
    case keyword |> String.replace(",", "") |> Integer.parse() do
      {num, ""} ->
        if num > @max_integer || num < 0 do
          {:error, :not_found}
        else
          case Repo.get_by(Block, number: num) do
            %Block{number: number} ->
              json(conn, %{type: "block", id: number})

            nil ->
              {:error, :not_found}
          end
        end

      _ ->
        cond do
          (udt = UDT.find_by_name_or_token(String.downcase(keyword))) != nil ->
            json(conn, %{type: "udt", id: udt.id})

          true ->
            {:error, :not_found}
        end
    end
  end
end
