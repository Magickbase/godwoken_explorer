defmodule GodwokenExplorer.Graphql.TokenTransfersTest do
  use GodwokenExplorerWeb.ConnCase

  @token_transfers """
  query {
    token_transfers(input: {from_address_hash: "0x3770f660a5b6fde2dadd765c0f336543ff285097", start_block_number: 300000, end_block_number:344620, page: 1, page_size: 1, sort_type: DESC}) {
      transaction_hash
      block_number
      to_account{
        id
        registry_address
      }
      to_address_hash
      from_account{
        id
        registry_address
      }
    }
  }
  """

  ## TODO: add factory data
  setup do
    :ok
  end

  test "query: token_transfers", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @token_transfers,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end
end
