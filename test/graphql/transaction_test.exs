defmodule GodwokenExplorer.Graphql.TransactionTest do
  use GodwokenExplorerWeb.ConnCase
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
end
