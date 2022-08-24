defmodule GodwokenExplorer.Graphql.UDTTest do
  use GodwokenExplorerWeb.ConnCase
  alias GodwokenExplorer.Factory

  setup do
    {:ok, script_hash} =
      GodwokenExplorer.Chain.Hash.cast(
        GodwokenExplorer.Chain.Hash.Full,
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      )

    native_udt = Factory.insert!(:native_udt)

    ckb_udt =
      Factory.insert!(:ckb_udt,
        script_hash: script_hash,
        bridge_account_id: native_udt.id,
        official_site: "official_site",
        description: "description"
      )

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
                 "udts" => %{
                   "entries" => _,
                   "metadata" => %{
                     "total_count" => 2
                   }
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: get_udt_by_id ", %{
    conn: conn,
    polyjuice_contract_account: polyjuice_contract_account
  } do
    id = polyjuice_contract_account.id

    query = """
    query {
      udt(input: {id: #{id}}){
        id
        bridge_account_id
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
                 "udt" => %{}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: get_udt_by_bridge_account_id ", %{
    conn: conn,
    ckb_udt: ckb_udt
  } do
    bridge_account_id = ckb_udt.bridge_account_id

    query = """
    query {
      udt(input: {bridge_account_id: #{bridge_account_id}}){
        id
        bridge_account_id
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
                 "udt" => %{}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: native udt holders ", %{
    conn: conn,
    ckb_udt: ckb_udt,
    native_udt: native_udt
  } do
    contract_address_hash = native_udt.contract_address_hash

    cub =
      Factory.insert!(:current_udt_balance,
        token_contract_address_hash: contract_address_hash,
        value: Enum.random(1..100_000)
      )

    _cbub =
      Factory.insert!(:current_bridged_udt_balance,
        address_hash: cub.address_hash,
        value: Enum.random(1..100_000),
        udt_id: ckb_udt.id,
        udt_script_hash: ckb_udt.script_hash
      )

    query = """
    query {
      udt(
        input: { contract_address: "#{contract_address_hash}" }
      ) {
        id
        name
        script_hash
        contract_address_hash
        holders_count
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
                 "udt" => %{
                   "holders_count" => 1
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: bridged udt holders ", %{
    conn: conn,
    ckb_udt: ckb_udt,
    native_udt: native_udt
  } do
    bridge_account_id = ckb_udt.bridge_account_id

    cub =
      Factory.insert!(:current_udt_balance,
        token_contract_address_hash: native_udt.contract_address_hash,
        value: Enum.random(1..100_000)
      )

    _cbub =
      Factory.insert!(:current_bridged_udt_balance,
        address_hash: cub.address_hash,
        value: Enum.random(1..100_000),
        udt_id: ckb_udt.id,
        udt_script_hash: ckb_udt.script_hash
      )

    query = """
    query {
      udt(input: {bridge_account_id: #{bridge_account_id}}){
        id
        bridge_account_id
        name
        type
        holders_count
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
                 "udt" => %{
                   "holders_count" => 1
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: native udt merge bridge udt info ", %{
    conn: conn,
    native_udt: native_udt,
    ckb_udt: %{official_site: official_site, description: description}
  } do
    contract_address_hash = native_udt.contract_address_hash

    query = """
    query {
      udt(
        input: { contract_address: "#{contract_address_hash}" }
      ) {
        id
        name
        description
        official_site
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
                 "udt" => %{
                   "official_site" => ^official_site,
                   "description" => ^description
                 }
               }
             },
             json_response(conn, 200)
           )
  end
end
