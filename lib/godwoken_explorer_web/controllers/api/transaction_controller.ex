defmodule GodwokenExplorerWeb.API.TransactionController do
  use GodwokenExplorerWeb, :controller

  action_fallback GodwokenExplorerWeb.API.FallbackController

  import GodwokenRPC.Util, only: [balance_to_view: 2]

  alias GodwokenExplorer.{Transaction, Account, Repo, PendingTransaction}

  # TODO: Remove after safepal is no longer used
  def index(conn, %{"eth_address" => "0x" <> _, "contract_address" => "0x" <> _} = params) do
    results =
      with %Account{type: type} = account when type in [:eth_user, :tron_user] <-
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

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    results =
      with %Account{type: type} = account <-
             Account.search(String.downcase(params["eth_address"])) do
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
      %Transaction{type: :polyjuice, eth_hash: eth_hash} ->
        {:error, :eth_hash, eth_hash}

      _ ->
        tx = Transaction.find_by_hash(downcased_hash)

        result =
          if is_nil(tx) do
            case PendingTransaction.find_by_hash(String.downcase(params["hash"])) do
              nil ->
                %{
                  error_code: 404,
                  message: "not found"
                }

              tx = %PendingTransaction{} ->
                base_struct = %{
                  hash: tx.hash,
                  timestamp: nil,
                  finalize_state: nil,
                  l2_block: nil,
                  l1_block: nil,
                  from: elem(Account.display_id(tx.from_account_id), 0),
                  to: elem(Account.display_id(tx.to_account_id), 0),
                  to_alias: elem(Account.display_id(tx.to_account_id), 1),
                  nonce: tx.nonce,
                  type: tx.type,
                  fee: tx |> Map.get(:fee, Decimal.new(0))
                }

                if tx.type == :polyjuice do
                  Map.merge(base_struct, %{
                    gas_price: balance_to_view(tx.parsed_args["gas_price"], 8),
                    gas_limit: tx.parsed_args["gas_limit"],
                    value: balance_to_view(tx.parsed_args["value"], 8),
                    input: tx.parsed_args["input"]
                  })
                else
                  base_struct
                end
            end
          else
            tx
          end

        json(
          conn,
          result
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
