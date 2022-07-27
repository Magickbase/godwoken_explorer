defmodule GodwokenExplorer.Graphql.SmartContractTest do
  use GodwokenExplorerWeb.ConnCase
  alias GodwokenExplorer.Factory

  setup do
    smart_contract = Factory.insert!(:smart_contract)
    [smart_contract: smart_contract]
  end

  test "graphql: smart_contract ", %{conn: conn, smart_contract: smart_contract} do
    account = smart_contract.account

    query = """
    query {
      smart_contract(
        input: { contract_address: "#{account.eth_address}" }
      ) {
        name
        account_id
        account {
          eth_address
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
                 "smart_contract" => %{}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: smart_contracts ", %{conn: conn} do
    query = """
    query {
      smart_contracts(input: { sorter: [{ sort_type: ASC, sort_value: ID }] }) {
        entries {
          name
          account_id
          account {
            eth_address
          }
        }
        metadata {
          total_count
          after
          before
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
                 "smart_contracts" => %{
                   "entries" => _
                 }
               }
             },
             json_response(conn, 200)
           )
  end
end
