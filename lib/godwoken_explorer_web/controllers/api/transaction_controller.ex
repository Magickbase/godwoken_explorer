defmodule GodwokenExplorerWeb.API.TransactionController do
  use GodwokenExplorerWeb, :controller

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.{Transaction, Account, Repo, Polyjuice, PendingTransaction}

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    %Account{id: account_id} = Account.search(String.downcase(params["eth_address"]))
    results = Transaction.account_transactions_data(account_id, params["page"])

    json(conn, results)
  end

  def index(conn, %{"account_id" => _} = params) do
    results = Transaction.account_transactions_data(params["account_id"], params["page"])

    json(conn, results)
  end

  def show(conn, %{"hash" => "0x" <> _} = params) do
    downcased_hash = String.downcase(params["hash"])
    tx = Transaction.find_by_hash(downcased_hash)

    result =
      if map_size(tx) == 0 do
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
              from: Account.display_id(tx.from_account_id),
              to: Account.display_id(tx.to_account_id),
              nonce: tx.nonce,
              args: tx.args,
              type: tx.type,
              fee: tx |> Map.get(:fee, Decimal.new(0))
            }

            if tx.type == :polyjuice do
              Map.merge(base_struct, %{
                gas_price: tx.parsed_args["gas_price"],
                gas_limit: tx.parsed_args["gas_limit"],
                value: tx.parsed_args["value"],
              })
            else
              base_struct
            end
          end
      else
        base_struct = %{
          hash: tx.hash,
          timestamp: tx.timestamp,
          finalize_state: tx.status,
          l2_block: tx.l2_block_number,
          l1_block: tx.l1_block_number,
          from: tx.from,
          to: tx.to,
          nonce: tx.nonce,
          type: tx.type
        }

        if tx.type == :polyjuice do
          polyjuice = Repo.get_by(Polyjuice, tx_hash: tx.hash)

          Map.merge(base_struct, %{
            gas_price: polyjuice.gas_price,
            gas_used: polyjuice.gas_used,
            gas_limit: polyjuice.gas_limit,
            value: polyjuice.value,
            input: polyjuice.input
          })
          |> Polyjuice.merge_transfer_args()
        else
          base_struct
        end
        |> stringify_and_unix_maps()
      end

    json(
      conn,
      result
    )
  end

  def show(conn, params) do
    json(
      conn,
      %{message: "Oops! An invalid Txn hash has been entered: #{params['hash']}"}
    )
  end
end
