defmodule GodwokenExplorer.Graphql.UDTTest do
  use GodwokenExplorerWeb.ConnCase
  alias GodwokenExplorer.Factory

  setup do
    {:ok, script_hash} =
      GodwokenExplorer.Chain.Hash.cast(
        GodwokenExplorer.Chain.Hash.Full,
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      )

    ckb_udt = Factory.insert!(:ckb_udt, script_hash: script_hash)
    native_udt = Factory.insert!(:native_udt)

    polyjuice_contract_account =
      Factory.insert!(:polyjuice_contract_account,
        id: native_udt.id,
        eth_address: native_udt.contract_address_hash
      )

    [
      ckb_udt: ckb_udt,
      native_udt: native_udt,
      polyjuice_contract_account: polyjuice_contract_account
    ]
  end

  test "graphql: udt ", %{conn: conn, native_udt: native_udt} do
    contract_address_hash = native_udt.contract_address_hash

    query = """
    query {
      udt(
        input: { contract_address: "#{contract_address_hash}" }
      ) {
        id
        name
        script_hash
        contract_address_hash
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
                 "udt" => %{}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: udts ", %{conn: conn, native_udt: native_udt} do
    _contract_address_hash = native_udt.contract_address_hash

    query = """
    query {
      udts(
        input: {
          limit: 3
          sorter: [{ sort_type: ASC, sort_value: NAME }]
        }
      ) {
        entries {
          id
          name
          type
          supply
          account {
            eth_address
            script_hash
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
                 "udts" => %{}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: get_udt_by_account_id ", %{
    conn: conn,
    polyjuice_contract_account: polyjuice_contract_account
  } do
    id = polyjuice_contract_account.id

    query = """
    query {
      get_udt_by_account_id(input: {account_id: #{id}}){
        id
        name
        type
        supply
        account{
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
                 "get_udt_by_account_id" => %{}
               }
             },
             json_response(conn, 200)
           )
  end
end
