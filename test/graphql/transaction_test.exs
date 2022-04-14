defmodule GodwokenExplorer.Graphql.TransactionTest do
  use GodwokenExplorerWeb.ConnCase

  @transaction """
  query {
    transaction (input: {transaction_hash: "0x21d6428f5325fc3632fb4762d40a1833a4e739329ca5bcb1de0a91fb519cf8a4"}) {
      hash
      block_hash
      block_number
      type
      from_account_id
      to_account_id
    }
  }
  """

  @transactions """
  query {
    transactions (input: {address: "0xc5e133e6b01b2c335055576c51a53647b1b9b624",  page: 1, page_size: 2, start_block_number: 335796, end_block_number: 341275}) {
      block_hash
      block_number
      type
      from_account_id
      to_account_id
    }
  }G
  """

  ## TODO: add factory data
  setup do
    :ok
  end

  test "query: transaction", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @transaction,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end

  test "query: transactions", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @transactions,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end
end
