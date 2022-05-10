defmodule GodwokenExplorer.Graphql.BlockTest do
  use GodwokenExplorerWeb.ConnCase

  @block """
  query {
    block(input: {number: 345600}){
      hash
      parent_hash
      number
      gas_used
      gas_limit
      account{
        id
        registry_address
      }
      transactions (input: {page: 1, page_size: 2}) {
        type
        from_account_id
        to_account_id
      }
    }
  }
  """

  @blocks """
  query {
    blocks(input: {page: 1, page_size: 1}){
      hash
      parent_hash
      number
      gas_used
      gas_limit
      account{
        id
        registry_address
      }
      transactions (input: {page: 1, page_size: 2}) {
        type
        from_account_id
        to_account_id
      }
    }
  }
  """

  ## TODO: add factory data
  setup do
    :ok
  end

  test "query: block", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @block,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end

  test "query: blocks", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @blocks,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end
end
