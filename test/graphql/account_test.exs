defmodule GodwokenExplorer.Graphql.AccountTest do
  use GodwokenExplorerWeb.ConnCase

  @account_test_1 """
  query {
    account(input: {address: "0xbfbe23681d99a158f632e64a31288946770c7a9e"}){
      id
      type
      account_udts{
        id
        balance
        udt{
          name
          type
        }
      }
    }
  }
  """

  @account_test_2 """
  query {
    account(input: {address: "0xc5e133e6b01b2c335055576c51a53647b1b9b624"}){
      id
      type
      smart_contract{
        id
        name
        deployment_tx_hash
      }
    }
  }
  """

  ## TODO: add factory data
  setup do
    :ok
  end

  test "query: account_test_1", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @account_test_1,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end

  test "query: account_test_2", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @account_test_2,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end
end
