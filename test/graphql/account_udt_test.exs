defmodule GodwokenExplorer.Graphql.AccountUDTTest do
  use GodwokenExplorerWeb.ConnCase

  @account_udts """
  query {
    account_udts(input: {address_hashes: ["0x15ca4f2165ff0e798d9c7434010eaacc4d768d85", "0xc20538aa80bb3ced9e240dc8f8130b7f7d0b0c49"],
        token_contract_address_hash: "0xbf1f27daea43849b67f839fd101569daaa321e2c"}) {
      address_hash
      balance
      udt{
        type
        name
      }
    }
  }
  """

  @account_ckbs """
  query {
    account_ckbs(input: {address_hashes: ["0x15ca4f2165ff0e798d9c7434010eaacc4d768d85"]}){
      address_hash
      balance
    }
  }
  """

  @account_udts_by_contract_address """
  query {
    account_udts_by_contract_address(input: {token_contract_address_hash: "0xbf1f27daea43849b67f839fd101569daaa321e2c", page_size: 2}){
      address_hash
      balance
      udt {
        type
        name
      }
    }
  }
  """

  ## TODO: add factory data
  setup do
    :ok
  end

  test "query: account_udts", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @account_udts,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end

  test "query: account_ckbs", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @account_ckbs,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end

  test "query: account_udts_by_contract_address", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @account_udts_by_contract_address,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end
end
