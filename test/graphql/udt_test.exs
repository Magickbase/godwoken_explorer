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

    erc721_native_udt = Factory.insert!(:native_udt, eth_type: :erc721)
    erc1155_native_udt = Factory.insert!(:native_udt, eth_type: :erc1155)

    user = Factory.insert!(:user)

    _erc721_cub1 =
      Factory.insert!(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: 1,
        token_type: :erc721
      )

    _erc721_cub2 =
      Factory.insert!(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: 2,
        token_type: :erc721
      )

    _erc1155_cub1 =
      Factory.insert!(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc1155_native_udt.contract_address_hash,
        token_id: 3,
        token_type: :erc1155
      )

    _erc1155_cub2 =
      Factory.insert!(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc1155_native_udt.contract_address_hash,
        token_id: 4,
        token_type: :erc1155
      )

    [
      ckb_udt: ckb_udt,
      native_udt: native_udt,
      polyjuice_contract_account: polyjuice_contract_account,
      user: user,
      erc721_native_udt: erc721_native_udt,
      erc1155_native_udt: erc1155_native_udt
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
          sorter: [{ sort_type: ASC, sort_value: NAME }, {sort_type: DESC, sort_value: EX_HOLDERS_COUNT}]
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
          holders_count
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
                     "total_count" => 4
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

  test "graphql: erc1155_user_token", %{
    conn: conn,
    user: user,
    # erc721_native_udt: erc721_native_udt,
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc1155_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc1155_user_token(
        input: { contract_address: "#{contract_address}", user_address: "#{user.eth_address}", token_id: 3}
      ) {
        address_hash
        token_contract_address_hash
        token_id
        token_type
        value
        udt {
          id
          name
          eth_type
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
                 "erc1155_user_token" => %{"token_contract_address_hash" => ^contract_address}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc721_udts", %{
    conn: conn,
    # user: user,
    erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc721_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc721_udts(
        input: { contract_address: "#{contract_address}"}
      ) {
        entries {
          id
          name
          contract_address_hash
          eth_type
          holders_count
          minted_count
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
                 "erc721_udts" => %{"metadata" => %{"total_count" => 1}}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc1155_udts", %{
    conn: conn,
    # user: user,
    # erc721_native_udt: erc721_native_udt
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc1155_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc1155_udts(
        input: { contract_address: "#{contract_address}"}
      ) {
        entries {
          id
          name
          contract_address_hash
          eth_type
          holders_count
          minted_count
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
                 "erc1155_udts" => %{"metadata" => %{"total_count" => 1}}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc721_holders", %{
    conn: conn,
    # user: user,
    erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc721_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc721_holders(
        input: { contract_address: "#{contract_address}"}
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          value
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
                 "erc721_holders" => %{"metadata" => %{"total_count" => 1}}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc1155_holders", %{
    conn: conn,
    # user: user,
    # erc721_native_udt: erc721_native_udt
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc1155_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc1155_holders(
        input: { contract_address: "#{contract_address}"}
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          value
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
                 "erc1155_holders" => %{"metadata" => %{"total_count" => 1}}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: user_erc721_assets", %{
    conn: conn,
    user: user
    # erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    user_address = user.eth_address |> to_string()

    query = """
    query {
      user_erc721_assets(
        input: { user_address: "#{user_address}"}
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          value
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
                 "user_erc721_assets" => %{"metadata" => %{"total_count" => 2}}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: user_erc1155_assets", %{
    conn: conn,
    user: user
    # erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    user_address = user.eth_address |> to_string()

    query = """
    query {
      user_erc1155_assets(
        input: { user_address: "#{user_address}"}
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          value
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
                 "user_erc1155_assets" => %{"metadata" => %{"total_count" => 2}}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc721_erc1155_inventory", %{
    conn: conn,
    # user: user
    erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc721_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc721_erc1155_inventory(
        input: { contract_address: "#{contract_address}"}
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          value
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
                 "erc721_erc1155_inventory" => %{"metadata" => %{"total_count" => 2}}
               }
             },
             json_response(conn, 200)
           )
  end
end
