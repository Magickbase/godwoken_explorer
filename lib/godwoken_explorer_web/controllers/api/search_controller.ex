defmodule GodwokenExplorerWeb.API.SearchController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Repo, Account, Block, Transaction}

  def index(conn, %{"keyword" => "0x" <> _} = params)do
    result = cond do
      (block = Repo.get_by(Block, hash: params["keyword"])) != nil ->  %{type: "block", id: block.number}
      (transaction = Repo.get_by(Transaction, hash: params["keyword"])) != nil -> %{type: "transaction", id: transaction.hash}
      (account = Account.search(params["keyword"])) != nil ->  %{type: "account", id: account.id}
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
  def index(conn, params) do
    result = case Integer.parse(params["keyword"]) do
      :error -> %{
          error_code: 404,
          message: "not found"
        }
      integer ->
        case Repo.get_by(Account, id: params["keyword"]) do
          %Account{id: id} -> %{type: "account", id: id}
          nil -> %{
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
