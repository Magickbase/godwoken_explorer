defmodule GodwokenExplorer.Graphql.UDTTest do
  use GodwokenExplorerWeb.ConnCase

  @udt """
  query {
    udt(input: {contract_address: "0xbf1f27daea43849b67f839fd101569daaa321e2c"}){
      id
      name
      type
      supply
      account{
        registry_address
      }
    }
  }
  """

  @udts """
  query {
    udts(input: {page: 1, page_size: 2, sort_type: ASC}){
      id
      name
      type
      supply
      account{
        eth_address
        registry_address
      }
    }
  }
  """

  ## TODO: add factory data
  setup do
    :ok
  end

  test "query: udt", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @udt,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end

  test "query: udts", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @udts,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end
end
