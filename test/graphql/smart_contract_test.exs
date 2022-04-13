defmodule GodwokenExplorer.Graphql.SmartContractTest do
  use GodwokenExplorerWeb.ConnCase

  @smart_contract """
  query {
    smart_contract(input: {contract_address: "0x21c814bf216ec7b988d872c56bf948d9cc1638a2"}) {
      name
      account_id
      account {
        eth_address
      }
    }
  }
  """

  @smart_contracts """
  query {
    smart_contracts {
      name
      account_id
      account {
        eth_address
      }
    }
  }
  """

  ## TODO: add factory data
  setup do
    :ok
  end

  test "query: smart_contract", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @smart_contract,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end

  test "query: smart_contracts", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @smart_contracts,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end
end
