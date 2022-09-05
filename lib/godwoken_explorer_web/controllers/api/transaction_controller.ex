defmodule GodwokenExplorerWeb.API.TransactionController do
  use GodwokenExplorerWeb, :controller

  action_fallback GodwokenExplorerWeb.API.FallbackController

  alias GodwokenExplorer.Chain.Exporter.TransactionCsv
  alias GodwokenExplorer.{Account, Chain, Repo, Transaction}

  # TODO: Remove after safepal is no longer used
  def index(conn, %{"eth_address" => "0x" <> _, "contract_address" => "0x" <> _} = params) do
    results =
      with %Account{type: type} = account when type in [:eth_user] <-
             Account |> Repo.get_by(eth_address: String.downcase(params["eth_address"])),
           %Account{type: :polyjuice_contract} = contract <-
             Repo.get_by(Account, eth_address: params["contract_address"]) do
        Transaction.account_transactions_data(
          %{
            account: account,
            contract: contract
          },
          %{
            page: conn.params["page"] || 1,
            page_size: conn.assigns.page_size
          }
        )
      else
        _ ->
          %{
            page: 1,
            total_count: 0,
            txs: []
          }
      end

    json(conn, results)
  end

  def index(conn, %{"eth_address" => "0x" <> _, "export" => "true"} = params) do
    with {:ok, address_hash} <-
           Chain.string_to_address_hash(params["eth_address"]),
         %Account{type: type} = account <-
           Repo.get_by(Account, eth_address: address_hash) do
      results =
        Transaction.account_transactions_data(
          %{type: type, account: account},
          nil
        )

      TransactionCsv.export(results)
      |> Enum.reduce_while(
        conn
        |> put_resp_content_type("application/csv")
        |> put_resp_header("content-disposition", "attachment; filename=transactions.csv")
        |> send_chunked(200),
        fn chunk, conn ->
          case Plug.Conn.chunk(
                 conn,
                 chunk
               ) do
            {:ok, conn} ->
              {:cont, conn}

            {:error, :closed} ->
              {:halt, conn}
          end
        end
      )
    else
      _ ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    results =
      with {:ok, address_hash} <-
             Chain.string_to_address_hash(params["eth_address"]),
           %Account{type: type} = account <-
             Repo.get_by(Account, eth_address: address_hash) do
        Transaction.account_transactions_data(
          %{type: type, account: account},
          %{
            page: conn.params["page"] || 1,
            page_size: conn.assigns.page_size
          }
        )
      else
        nil ->
          %{
            page: 1,
            total_count: 0,
            txs: []
          }
      end

    json(conn, results)
  end

  def index(conn, %{"block_hash" => "0x" <> _, "export" => "true"} = params) do
    results =
      Transaction.account_transactions_data(
        %{block_hash: params["block_hash"]},
        nil
      )

    TransactionCsv.export(results)
    |> Enum.reduce_while(
      conn
      |> put_resp_content_type("application/csv")
      |> put_resp_header("content-disposition", "attachment; filename=transactions.csv")
      |> send_chunked(200),
      fn chunk, conn ->
        case Plug.Conn.chunk(
               conn,
               chunk
             ) do
          {:ok, conn} ->
            {:cont, conn}

          {:error, :closed} ->
            {:halt, conn}
        end
      end
    )
  end

  def index(conn, %{"block_hash" => "0x" <> _} = params) do
    results =
      Transaction.account_transactions_data(
        %{block_hash: params["block_hash"]},
        %{
          page: conn.params["page"] || 1,
          page_size: conn.assigns.page_size
        }
      )

    json(conn, results)
  end

  def index(conn, _params) do
    results =
      Transaction.account_transactions_data(%{
        page: conn.params["page"] || 1,
        page_size: conn.assigns.page_size
      })

    json(conn, results)
  end

  def show(conn, %{"hash" => "0x" <> _} = params) do
    downcased_hash = String.downcase(params["hash"])

    case Repo.get_by(Transaction, hash: downcased_hash) do
      %Transaction{type: :polyjuice, eth_hash: eth_hash} when not is_nil(eth_hash) ->
        {:error, :eth_hash, eth_hash}

      _ ->
        tx = Transaction.find_by_hash(downcased_hash)

        json(
          conn,
          tx
        )
    end
  end

  def show(conn, params) do
    json(
      conn,
      %{message: "Oops! An invalid Txn hash has been entered: #{params['hash']}"}
    )
  end
end
