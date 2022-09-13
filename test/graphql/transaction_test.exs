defmodule GodwokenExplorer.Graphql.TransactionTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.Factory

  setup do
    {:ok, args} =
      GodwokenExplorer.Chain.Data.cast(
        "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000"
      )

    transaction = Factory.insert!(:transaction, args: args)

    [transaction: transaction]
  end

  test "graphql: transaction ", %{conn: conn, transaction: transaction} do
    eth_hash = transaction.eth_hash |> to_string()

    query = """
    query {
        transaction(
          input: {
            eth_hash: "#{eth_hash}"
          }
        ) {
          hash
          nonce
          type
          index
          from_account {
            eth_address
            type
          }
          to_account {
            eth_address
            type
          }
          polyjuice {
            is_create
            value
            status
            input
            created_contract_address_hash
            gas_used
            gas_limit
            gas_price
          }
          block {
            number
            hash
            timestamp
            status
            layer1_block_number
          }
        }
      }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "transaction" => %{}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: transactions ", %{conn: conn, transaction: _transaction} do
    query = """
    query {
      transactions(
        input: {
          limit: 1
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: HASH }
            { sort_type: ASC, sort_value: INDEX }
          ]
        }
      ) {
        entries {
          hash
          eth_hash
          block_hash
          block_number
          type
          from_account_id
          from_account {
            script_hash
            id
            eth_address
          }
          to_account_id
        }

        metadata {
          total_count
          before
          after
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "transactions" => %{
                   "entries" => _,
                   "metadata" => %{
                     "total_count" => 1
                   }
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: transactions with method id and method name", %{
    conn: conn
  } do
    user = Factory.insert(:user)
    contract = Factory.insert(:polyjuice_contract_account)

    _udt =
      Factory.insert(:native_udt,
        id: contract.id,
        type: :native,
        name: "CKB",
        symbol: "CKB",
        decimal: 8,
        contract_address_hash: contract.eth_address
      )

    block = Factory.insert(:block)

    transaction =
      :transaction
      |> Factory.insert(
        from_account: user,
        to_account: contract,
        block_number: block.number,
        block: block
      )

    polyjuice = Factory.insert(:polyjuice, transaction: transaction)

    eth_hash = transaction.eth_hash |> to_string()
    input = polyjuice.input |> to_string()
    method_id = String.slice(input, 0, 10)

    query = """
    query {
      transaction(
        input: {
          eth_hash: "#{eth_hash}"
        }
      ) {
        hash
        from_account_id
        to_account_id
        method_id
        method_name
        polyjuice {
          input
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "transaction" => %{
                   "method_id" => ^method_id
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "pending transaction", %{conn: conn} do
    pending_tx = insert(:pending_transaction)

    query = """
    query {
      transactions(
        input: {
          status: PENDING
        }
      ) {
        entries {
          hash
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "transactions" => %{
                   "entries" => [%{"hash" => pending_tx.hash |> to_string()}]
                 }
               }
             }
  end

  test "native transfer transaction", %{conn: conn} do
    block = insert(:block)
    eth_user = insert(:user)
    polyjuice_creator_account = insert(:polyjuice_creator_account)
    receiver_user = insert(:user)

    native_transfer_tx =
      insert(:transaction,
        block: block,
        block_number: block.number,
        from_account: eth_user,
        to_account: polyjuice_creator_account,
        index: 2,
        args:
          "0xffffff504f4c590068bf00000000000000a007c2da51000000000000000000000000e867ce97461d310000000000000000000000715ab282b873b79a7be8b0e8c13c4e8966a52040"
      )

    native_transfer_polyjuice =
      insert(:polyjuice,
        transaction: native_transfer_tx,
        native_transfer_address_hash: receiver_user.eth_address
      )

    query = """
    query {
      transactions(
        input: {
          from_eth_address: "#{receiver_user.eth_address |> to_string()}",
          to_eth_address: "#{receiver_user.eth_address |> to_string()}"
        }
      ) {
        entries {
          hash
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "transactions" => %{
                   "entries" => [%{"hash" => native_transfer_tx.hash |> to_string()}]
                 }
               }
             }
  end
end
