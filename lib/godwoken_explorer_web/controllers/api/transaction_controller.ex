defmodule GodwokenExplorerWeb.API.TransactionController do
  use GodwokenExplorerWeb, :controller

  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.{Transaction, Account, Repo, PendingTransaction}

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    %Account{id: account_id, type: type, eth_address: eth_address} = Account.search(String.downcase(params["eth_address"]))
    results = Transaction.account_transactions_data(%{type: type, account_id: account_id, eth_address: eth_address},  conn.assigns[:page] || 1)

    json(conn, results)
  end

  def index(conn, %{"eth_address" => "0x" <> _, "contract_address" => "0x" <> _} = params) do
    with %Account{id: account_id, type: :user, eth_address: eth_address} <- Account.search(String.downcase(params["eth_address"])),
       %Account{id: contract_id, type: :polyjuice_contract} <- Repo.get_by(Account, short_address: params["contract_address"]) do
      results = Transaction.account_transactions_data(%{type: :user, account_id: account_id, eth_address: eth_address, contract_id: contract_id}, conn.assigns[:page] || 1)
      json(conn, results)
    else
      _ ->
        %{
          error_code: 404,
          message: "not found"
        }
    end
  end

  def index(conn, %{"account_id" => _} = params) do
    %Account{id: account_id, type: type, eth_address: eth_address} = Repo.get(Account, params["account_id"])
    results = Transaction.account_transactions_data(%{type: type, account_id: account_id, eth_address: eth_address}, conn.assigns[:page] || 1)

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
                receive_address: tx.parsed_args["receive_address"],
                transfer_count: tx.parsed_args["transfer_count"]
              })
            else
              base_struct
            end
          end
      else
        stringify_and_unix_maps(tx)
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
