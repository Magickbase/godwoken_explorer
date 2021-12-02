defmodule GodwokenExplorerWeb.API.SearchController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Repo, Account, Block, Transaction}

  # 0x0000000000000000000000000000000000000000000000000000000000000001_data_0x06820f679f7c9c6e399dcb25ab88a5babaf7d5db
  def index(conn, %{"keyword" => script} = params) when byte_size(script) > 73 do
    result =
      case params["keyword"] |> String.split("_") do
        [_code_hash, _hash_type, args] ->
          Account.find_by_ckb_args(args)

        _ ->
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

  def index(conn, %{"keyword" => "0x" <> _} = params) do
    downcase_keyword = String.downcase(params["keyword"])

    result =
      cond do
        (block = Repo.get_by(Block, hash: downcase_keyword)) != nil ->
          %{type: "block", id: block.number}

        (transaction = Repo.get_by(Transaction, hash: downcase_keyword)) != nil ->
          %{type: "transaction", id: transaction.hash}

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
