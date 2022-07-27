defmodule GodwokenExplorer.Graphql.BlockTest do
  use GodwokenExplorerWeb.ConnCase

  alias GodwokenExplorer.Factory

  setup do
    block = Factory.insert!(:block)

    [block: block]
  end

  test "graphql: block ", %{conn: conn, block: block} do
    number = block.number

    query = """
    query {
      block(input: {number: #{number}}){
        hash
        parent_hash
        number
        gas_used
        gas_limit
        account{
          id
          eth_address
        }
        transactions (input: {page: 1, page_size: 2}) {
          type
          from_account_id
          to_account_id
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
                 "block" => %{
                   "number" => ^number
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: blocks ", %{conn: conn, block: block} do
    number = block.number

    query = """
    query {
      blocks(input: {}){
        hash
        parent_hash
        number
        gas_used
        gas_limit
        producer_address
        account{
          eth_address
        }
        transactions (input: {page: 1, page_size: 2}) {
          type
          from_account_id
          to_account_id
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
                 "blocks" => [
                   %{
                     "number" => ^number
                   }
                 ]
               }
             },
             json_response(conn, 200)
           )
  end
end
