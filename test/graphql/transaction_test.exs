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
                 "transactions" => %{}
               }
             },
             json_response(conn, 200)
           )
  end
end
