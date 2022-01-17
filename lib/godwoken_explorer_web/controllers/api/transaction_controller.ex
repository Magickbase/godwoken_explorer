defmodule GodwokenExplorerWeb.API.TransactionController do
  use GodwokenExplorerWeb, :controller

  import GodwokenRPC.Util, only: [balance_to_view: 2]

  alias GodwokenExplorer.{Transaction, Account, Repo, PendingTransaction, UDT}

  def index(conn, %{"eth_address" => "0x" <> _, "contract_address" => "0x" <> _} = params) do
    results =
      with %Account{id: account_id, type: :user, eth_address: eth_address} <-
             Account.search(String.downcase(params["eth_address"])),
           %Account{id: contract_id, type: :polyjuice_contract} <-
             Repo.get_by(Account, short_address: params["contract_address"]) do
        Transaction.account_transactions_data(
          %{
            type: :user,
            account_id: account_id,
            eth_address: eth_address,
            contract_id: contract_id
          },
          conn.params["page"] || 1
        )
      else
        _ ->
          %{
            error_code: 404,
            message: "not found"
          }
      end

    json(conn, results)
  end

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    %Account{id: account_id, type: type, eth_address: eth_address} =
      Account.search(String.downcase(params["eth_address"]))

    results =
      Transaction.account_transactions_data(
        %{type: type, account_id: account_id, eth_address: eth_address},
        conn.params["page"] || 1
      )

    json(conn, results)
  end

  def index(conn, %{"udt_address" => "0x" <> _} = params) do
    %Account{id: account_id} =
      Repo.get_by(Account, short_address: String.downcase(params["udt_address"]))

    results =
      Transaction.account_transactions_data(
        %{udt_account_id: account_id},
        conn.params["page"] || 1
      )

    json(conn, results)
  end

  def index(conn, %{"block_hash" => "0x" <> _} = params) do
    results =
      Transaction.account_transactions_data(
        %{block_hash: params["block_hash"]},
        conn.params["page"] || 1
      )

    json(conn, results)
  end

  # Compatible with old api
  def index(conn, %{"account_id" => _, "tx_type" => _tx_type} = params) do
    %Account{id: account_id} = Repo.get(Account, params["account_id"])

    results =
      Transaction.account_transactions_data(
        %{udt_account_id: account_id},
        conn.params["page"] || 1
      )

    json(conn, results)
  end

  def index(conn, _params) do
    results = Transaction.account_transactions_data(conn.params["page"] || 1)

    json(conn, results)
  end

  def show(conn, %{"hash" => "0x" <> _} = params) do
    downcased_hash = String.downcase(params["hash"])
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
                receive_eth_address: tx.parsed_args["receive_eth_address"],
                input: tx.parsed_args["input"],
                transfer_count:
                  balance_to_view(
                    tx.parsed_args["transfer_count"],
                    UDT.get_decimal(tx.to_account_id)
                  ),

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

  def show(conn, params) do
    json(
      conn,
      %{message: "Oops! An invalid Txn hash has been entered: #{params['hash']}"}
    )
  end
end
