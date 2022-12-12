defmodule GodwokenExplorer.Graphql.UDTTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory, only: [insert!: 1, insert!: 2, address_hash: 0, insert: 2]

  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Chain.Cache.TokenExchangeRate
  alias GodwokenExplorer.Counters.Helper

  setup do
    {:ok, script_hash} =
      GodwokenExplorer.Chain.Hash.cast(
        GodwokenExplorer.Chain.Hash.Full,
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      )

    symbol = "CKB.ETH"
    native_udt = insert!(:native_udt, symbol: symbol, uan: symbol)
    fetch_symbol = hd(String.split(symbol, "."))

    TokenExchangeRate.put_into_cache(
      "#{TokenExchangeRate.cache_key(fetch_symbol)}_last_update",
      Helper.current_time()
    )

    exchange_rate = Decimal.new(10086)
    TokenExchangeRate.put_into_cache(TokenExchangeRate.cache_key(fetch_symbol), exchange_rate)

    ckb_udt =
      insert!(:ckb_udt,
        script_hash: script_hash,
        bridge_account_id: native_udt.id,
        official_site: "official_site",
        description: "description"
      )

    polyjuice_contract_account =
      insert!(:polyjuice_contract_account,
        id: native_udt.id,
        eth_address: native_udt.contract_address_hash
      )

    erc721_native_udt = insert!(:native_udt, eth_type: :erc721)
    _erc721_native_udt2 = insert!(:native_udt, eth_type: :erc721)
    erc1155_native_udt = insert!(:native_udt, eth_type: :erc1155)
    _erc1155_native_udt2 = insert!(:native_udt, eth_type: :erc1155)

    user = insert!(:user)

    _erc721_token_instance =
      _erc721_cub1 =
      insert!(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: 1,
        block_number: 1,
        value: 1,
        token_type: :erc721
      )

    _erc721_cub2 =
      insert!(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: 2,
        value: 2,
        block_number: 2,
        token_type: :erc721
      )

    for index <- 3..5 do
      insert!(:current_udt_balance,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: index,
        value: 1,
        block_number: 3,
        token_type: :erc721
      )
    end

    _erc721_token_instance =
      insert!(:token_instance,
        token_id: 5,
        token_contract_address_hash: erc721_native_udt.contract_address_hash
      )

    _erc1155_cub1 =
      insert!(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc1155_native_udt.contract_address_hash,
        token_id: 6,
        token_type: :erc1155,
        value: 100
      )

    _erc1155_cub2 =
      insert!(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc1155_native_udt.contract_address_hash,
        token_id: 7,
        token_type: :erc1155,
        value: 100
      )

    _erc1155_cub3 =
      insert!(:current_udt_balance,
        token_contract_address_hash: erc1155_native_udt.contract_address_hash,
        token_id: 8,
        token_type: :erc1155,
        value: 100
      )

    for index <- 9..11 do
      insert!(:current_udt_balance,
        token_contract_address_hash: erc1155_native_udt.contract_address_hash,
        token_id: index,
        token_type: :erc1155,
        value: 100
      )
    end

    _erc1155_cu6 =
      insert!(:current_udt_balance,
        token_contract_address_hash: erc1155_native_udt.contract_address_hash,
        token_id: 11,
        token_type: :erc1155,
        value: 0
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

  test "show bridge udt's uan as name symbol", %{conn: conn, ckb_udt: ckb_udt} do
    query = """
    query {
      udt(
        input: { id: #{ckb_udt.id} }
      ) {
        name
        symbol
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "udt" => %{
                   "name" => ckb_udt.display_name,
                   "symbol" => ckb_udt.uan
                 }
               }
             }
  end

  test "show bridge udt's name symbol", %{conn: conn, ckb_udt: ckb_udt} do
    query = """
    query {
      udt(
        input: { id: #{ckb_udt.id} }
      ) {
        name
        symbol
      }
    }
    """

    UDT.changeset(ckb_udt, %{display_name: nil, uan: nil}) |> Repo.update()

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "udt" => %{
                   "name" => ckb_udt.name,
                   "symbol" => ckb_udt.symbol
                 }
               }
             }
  end

  test "graphql: udt ", %{conn: conn, native_udt: native_udt} do
    contract_address_hash = native_udt.contract_address_hash |> to_string()

    query = """
    query {
      udt(
        input: { contract_address: "#{contract_address_hash}" }
      ) {
        id
        symbol
        token_exchange_rate {
          symbol
          exchange_rate
          timestamp
        }
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
                 "udt" => %{
                   "token_exchange_rate" => %{
                     "exchange_rate" => _,
                     "symbol" => "CKB.ETH",
                     "timestamp" => _
                   }
                 }
               }
             },
             json_response(conn, 200)
           )

    not_exist_address = address_hash()

    query = """
    query {
      udt(
        input: { contract_address: "#{not_exist_address}" }
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
                 "udt" => nil
               }
             },
             json_response(conn, 200)
           )

    # id with null
    query = """
    query {
      udt(
        input: { id: null }
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
                 "udt" => nil
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc20 udts ", %{conn: conn, native_udt: native_udt} do
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
          rank
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

  test "graphql: erc20 udts with first page check ", %{conn: conn, native_udt: native_udt} do
    _contract_address_hash = native_udt.contract_address_hash

    _ = insert!(:native_udt)
    query = erc20_udts_with_first_page_check_base_query("")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "udts" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query = erc20_udts_with_first_page_check_base_query("after: \"#{after_value}\"")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "udts" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query = erc20_udts_with_first_page_check_base_query("before: \"#{before_value}\"")

    %{id: newest_id} = insert!(:native_udt)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "udts" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query = erc20_udts_with_first_page_check_base_query("before: \"#{before_value}\"")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "udts" => %{
          "entries" => [%{"id" => ^newest_id} | _] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp erc20_udts_with_first_page_check_base_query(before_or_after) do
    """
    query {
      udts(
        input: {
          limit: 2,
          sorter: [{ sort_type: DESC, sort_value: ID }],
          #{before_or_after}
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
          rank
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """
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
      insert!(:current_udt_balance,
        token_contract_address_hash: contract_address_hash,
        value: Enum.random(1..100_000)
      )

    _cbub =
      insert!(:current_bridged_udt_balance,
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
      insert!(:current_udt_balance,
        token_contract_address_hash: native_udt.contract_address_hash,
        value: Enum.random(1..100_000)
      )

    _cbub =
      insert!(:current_bridged_udt_balance,
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
        input: { contract_address: "#{contract_address}", user_address: "#{user.eth_address}", token_id: 6}
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
          rank
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

  test "graphql: erc721_udts with first page check ", %{conn: conn} do
    _ = insert!(:native_udt, eth_type: :erc721)
    query = erc721_udts_with_first_page_check_base_query("")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_udts" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query = erc721_udts_with_first_page_check_base_query("after: \"#{after_value}\"")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_udts" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query = erc721_udts_with_first_page_check_base_query("before: \"#{before_value}\"")

    %{id: newest_id} = insert!(:native_udt, eth_type: :erc721)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_udts" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query = erc721_udts_with_first_page_check_base_query("before: \"#{before_value}\"")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_udts" => %{
          "entries" => [%{"id" => ^newest_id} | _] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp erc721_udts_with_first_page_check_base_query(before_or_after) do
    """
    query {
      erc721_udts(
        input: {
          limit: 2,
          sorter: [{ sort_type: DESC, sort_value: ID }],
          #{before_or_after}
        }
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
  end

  test "graphql: erc721_udts with paginator", %{
    conn: conn
    # user: user,
    # erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    query = """
    query {
      erc721_udts(
        input: {limit: 1}
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

    %{
      "data" => %{
        "erc721_udts" => %{"metadata" => %{"after" => after_value}}
      }
    } = json_response(conn, 200)

    assert match?(
             %{
               "data" => %{
                 "erc721_udts" => %{"metadata" => %{"total_count" => 2}}
               }
             },
             json_response(conn, 200)
           )

    query = """
    query {
      erc721_udts(
        input: {limit: 1, after: "#{after_value}"}
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
                 "erc721_udts" => %{"metadata" => %{"total_count" => 2}}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc721_udts with holders_count sorter", %{
    conn: conn
    # user: user,
    # erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    # contract_address = erc721_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc721_udts(
        input: {limit: 1, sorter: [{sort_type: ASC, sort_value: EX_HOLDERS_COUNT}]
      }
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

    %{
      "data" => %{
        "erc721_udts" => %{"metadata" => %{"after" => after_value}}
      }
    } = json_response(conn, 200)

    assert match?(
             %{
               "data" => %{
                 "erc721_udts" => %{"metadata" => %{"total_count" => 2}}
               }
             },
             json_response(conn, 200)
           )

    query = """
    query {
      erc721_udts(
        input: {limit: 1, after: "#{after_value}", sorter: [{sort_type: ASC, sort_value: EX_HOLDERS_COUNT}]
      }
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
                 "erc721_udts" => %{"metadata" => %{"total_count" => 2}}
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
          token_type_count
          minted_count
          rank
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
                 "erc1155_udts" => %{
                   "entries" => [
                     %{
                       "contract_address_hash" => ^contract_address,
                       "eth_type" => "ERC1155",
                       "holders_count" => 5,
                       "token_type_count" => 6,
                       "minted_count" => "600"
                     }
                   ],
                   "metadata" => %{"total_count" => 1}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc1155_udts with first page check ", %{conn: conn} do
    _ = insert!(:native_udt, eth_type: :erc1155)
    query = erc1155_udts_with_first_page_check_base_query("")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_udts" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query = erc1155_udts_with_first_page_check_base_query("after: \"#{after_value}\"")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_udts" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query = erc1155_udts_with_first_page_check_base_query("before: \"#{before_value}\"")

    %{id: newest_id} = insert!(:native_udt, eth_type: :erc1155)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_udts" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query = erc1155_udts_with_first_page_check_base_query("before: \"#{before_value}\"")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_udts" => %{
          "entries" => [%{"id" => ^newest_id} | _] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp erc1155_udts_with_first_page_check_base_query(before_or_after) do
    """
    query {
      erc1155_udts(
        input: {
          limit: 2,
          sorter: [{ sort_type: DESC, sort_value: ID }],
          #{before_or_after}
        }
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
  end

  test "graphql: erc721_holders", %{
    conn: conn,
    user: user,
    erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    eth_address = user.eth_address |> to_string()
    contract_address = erc721_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc721_holders(
        input: { contract_address: "#{contract_address}"}
      ) {
        entries {
          rank
          address_hash
          token_contract_address_hash
          quantity
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
                 "erc721_holders" => %{
                   "entries" => [
                     %{
                       "rank" => 1,
                       "address_hash" => ^eth_address,
                       "quantity" => "2"
                     },
                     %{
                       "rank" => 2
                     },
                     %{
                       "rank" => 3
                     },
                     %{
                       "rank" => 4
                     }
                   ],
                   "metadata" => %{"total_count" => 4}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc721_holders with first page check ", %{
    conn: conn,
    erc721_native_udt: erc721_native_udt
  } do
    contract_address = erc721_native_udt.contract_address_hash |> to_string()
    query = erc721_holders_with_first_page_check_base_query(contract_address, "")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_holders" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc721_holders_with_first_page_check_base_query(
        contract_address,
        "after: \"#{after_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_holders" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    %{address_hash: address_hash} =
      insert(:current_udt_balance,
        token_contract_address_hash: contract_address,
        token_id: 100,
        value: 1,
        token_type: :erc721
      )

    for index <- 1..2 do
      insert(:current_udt_balance,
        address_hash: address_hash,
        token_contract_address_hash: contract_address,
        token_id: 100 + index,
        # this  value means holder's latest quantify of token
        value: 1 + index,
        token_type: :erc721
      )
    end

    query =
      erc721_holders_with_first_page_check_base_query(
        contract_address,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_holders" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc721_holders_with_first_page_check_base_query(
        contract_address,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_holders" => %{
          "entries" => [%{"quantity" => "3"} | _] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp erc721_holders_with_first_page_check_base_query(contract_address, before_or_after)
       when is_bitstring(contract_address) do
    """
    query {
      erc721_holders(
        input: {
          limit: 2,
          contract_address: "#{contract_address}",
          #{before_or_after}
        }
      ) {
        entries {
          rank
          address_hash
          token_contract_address_hash
          quantity
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """
  end

  test "graphql: erc721_holders with pagination", %{
    conn: conn,
    user: user,
    erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    eth_address = user.eth_address |> to_string()
    contract_address = erc721_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc721_holders(
        input: { limit: 1, contract_address: "#{contract_address}"}
      ) {
        entries {
          rank
          address_hash
          token_contract_address_hash
          quantity
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
                 "erc721_holders" => %{
                   "entries" => [
                     %{
                       "rank" => 1,
                       "quantity" => "2",
                       "address_hash" => ^eth_address
                     }
                   ],
                   "metadata" => %{"total_count" => 4}
                 }
               }
             },
             json_response(conn, 200)
           )

    %{
      "data" => %{
        "erc721_holders" => %{"metadata" => %{"after" => after_value}}
      }
    } = json_response(conn, 200)

    query = """
    query {
      erc721_holders(
        input: { after: "#{after_value}", limit: 1, contract_address: "#{contract_address}"}
      ) {
        entries {
          rank
          address_hash
          token_contract_address_hash
          quantity
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
                 "erc721_holders" => %{
                   "entries" => [
                     %{
                       "rank" => 2
                     }
                   ],
                   "metadata" => %{"total_count" => 4}
                 }
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
          rank
          address_hash
          token_contract_address_hash
          quantity
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
                 "erc1155_holders" => %{
                   "entries" => [
                     %{"rank" => 1},
                     %{"rank" => 2},
                     %{
                       "rank" => 3
                     },
                     %{
                       "rank" => 4
                     },
                     %{
                       "rank" => 5
                     }
                   ],
                   "metadata" => %{"total_count" => 5}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc1155_holders with first page check ", %{
    conn: conn,
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc1155_native_udt.contract_address_hash |> to_string()
    query = erc1155_holders_with_first_page_check_base_query(contract_address, "")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_holders" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc1155_holders_with_first_page_check_base_query(
        contract_address,
        "after: \"#{after_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_holders" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    %{address_hash: address_hash} =
      insert(:current_udt_balance,
        token_contract_address_hash: contract_address,
        token_id: 100,
        value: 100,
        token_type: :erc1155
      )

    for index <- 1..2 do
      insert(:current_udt_balance,
        address_hash: address_hash,
        token_contract_address_hash: contract_address,
        token_id: 100 + index,
        # this  value means holder's latest quantify of token
        value: 100 + index,
        token_type: :erc1155
      )
    end

    query =
      erc1155_holders_with_first_page_check_base_query(
        contract_address,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_holders" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc1155_holders_with_first_page_check_base_query(
        contract_address,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_holders" => %{
          "entries" => [%{"quantity" => "303"} | _] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp erc1155_holders_with_first_page_check_base_query(contract_address, before_or_after)
       when is_bitstring(contract_address) do
    """
    query {
      erc1155_holders(
        input: {
          limit: 2,
          contract_address: "#{contract_address}",
          #{before_or_after}
        }
      ) {
        entries {
          rank
          address_hash
          token_contract_address_hash
          quantity
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """
  end

  test "graphql: erc1155_holders with token_id", %{
    conn: conn,
    # user: user,
    # erc721_native_udt: erc721_native_udt
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc1155_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc1155_holders(
        input: { contract_address: "#{contract_address}", token_id: 6}
      ) {
        entries {
          rank
          address_hash
          token_contract_address_hash
          quantity
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
                 "erc1155_holders" => %{
                   "entries" => [
                     %{
                       "token_contract_address_hash" => ^contract_address,
                       "rank" => 1
                     }
                   ],
                   "metadata" => %{"total_count" => 1}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: user_erc721_assets", %{
    conn: conn,
    user: user,
    erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    user_address = user.eth_address |> to_string()
    erc721_udt_id = erc721_native_udt.id
    erc721_udt_name = erc721_native_udt.name
    erc721_udt_contract_address_hash = erc721_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      user_erc721_assets(
        input: {limit: 1, user_address: "#{user_address}"}
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          counts
          udt {
            id
            name
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
                 "user_erc721_assets" => %{
                   "entries" => [
                     %{
                       "address_hash" => ^user_address,
                       "token_contract_address_hash" => ^erc721_udt_contract_address_hash,
                       "token_type" => "ERC721",
                       "udt" => %{"id" => ^erc721_udt_id, "name" => ^erc721_udt_name}
                     }
                   ],
                   "metadata" => %{"total_count" => 2}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: user_erc1155_assets", %{
    conn: conn,
    user: user,
    # erc721_native_udt: erc721_native_udt
    erc1155_native_udt: erc1155_native_udt
  } do
    user_address = user.eth_address |> to_string()
    erc1155_udt_id = erc1155_native_udt.id
    erc1155_udt_name = erc1155_native_udt.name
    erc1155_udt_contract_address_hash = erc1155_native_udt.contract_address_hash |> to_string()

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
          counts
          udt {
            id
            name
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
                 "user_erc1155_assets" => %{
                   "entries" => [
                     %{
                       "address_hash" => ^user_address,
                       "token_contract_address_hash" => ^erc1155_udt_contract_address_hash,
                       "token_type" => "ERC1155",
                       "udt" => %{"id" => ^erc1155_udt_id, "name" => ^erc1155_udt_name}
                     },
                     _
                   ],
                   "metadata" => %{"total_count" => 2}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: user_erc1155_assets with first page check", %{
    conn: conn,
    user: user,
    # erc721_native_udt: erc721_native_udt
    erc1155_native_udt: erc1155_native_udt
  } do
    user_address = user.eth_address |> to_string()
    erc1155_udt_contract_address_hash = erc1155_native_udt.contract_address_hash |> to_string()

    for index <- 1..3 do
      _erc1155_cub =
        insert(:current_udt_balance,
          address_hash: user_address,
          token_contract_address_hash: erc1155_udt_contract_address_hash,
          token_id: 100 + index,
          token_type: :erc1155,
          value: 100
        )
    end

    query = user_erc1155_assets_first_page_check_query_base(user_address, "")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "user_erc1155_assets" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      user_erc1155_assets_first_page_check_query_base(user_address, "after: \"#{after_value}\"")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "user_erc1155_assets" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    # add more one
    %{id: _newest_id} =
      insert(:current_udt_balance,
        address_hash: user_address,
        token_contract_address_hash: erc1155_native_udt.contract_address_hash,
        token_id: 104,
        token_type: :erc1155,
        value: 100
      )

    query =
      user_erc1155_assets_first_page_check_query_base(user_address, "before: \"#{before_value}\"")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "user_erc1155_assets" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      user_erc1155_assets_first_page_check_query_base(user_address, "before: \"#{before_value}\"")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "user_erc1155_assets" => %{
          "entries" =>
            [
              %{
                "token_id" => "104"
              }
              | _
            ] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp user_erc1155_assets_first_page_check_query_base(user_address, before_or_after) do
    """
    query {
      user_erc1155_assets(
        input: {
          user_address: "#{user_address}",
          limit: 2,
          #{before_or_after}
        }
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          counts
          udt {
            id
            name
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
  end

  test "graphql: erc721_inventory", %{
    conn: conn,
    # user: user
    erc721_native_udt: erc721_native_udt
    # erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc721_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc721_inventory(
        input: {limit: 1, contract_address: "#{contract_address}"}
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          counts
          token_instance {
            token_contract_address_hash
            metadata
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
                 "erc721_inventory" => %{
                   "entries" => [
                     %{
                       "token_instance" => %{
                         "token_contract_address_hash" => ^contract_address
                       }
                     }
                   ],
                   "metadata" => %{"total_count" => 5}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc721_inventory with first page check", %{
    conn: conn,
    erc721_native_udt: erc721_native_udt
  } do
    contract_address_hash = erc721_native_udt.contract_address_hash |> to_string()

    query = erc721_inventory_first_page_check_query_base(contract_address_hash, "")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_inventory" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc721_inventory_first_page_check_query_base(
        contract_address_hash,
        "after: \"#{after_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_inventory" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    # add more one
    _ =
      insert(:current_udt_balance,
        token_contract_address_hash: contract_address_hash,
        token_id: 100,
        value: 1,
        token_type: :erc721
      )

    query =
      erc721_inventory_first_page_check_query_base(
        contract_address_hash,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_inventory" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc721_inventory_first_page_check_query_base(
        contract_address_hash,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc721_inventory" => %{
          "entries" =>
            [
              %{
                "token_id" => "100"
              }
              | _
            ] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp erc721_inventory_first_page_check_query_base(contract_address, before_or_after) do
    """
    query {
      erc721_inventory(
        input: {
          limit: 2,
          contract_address: "#{contract_address}",
          #{before_or_after}
        }
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          counts
          token_instance {
            token_contract_address_hash
            metadata
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
  end

  test "graphql: erc1155_user_inventory", %{
    conn: conn,
    # user: user
    # erc721_native_udt: erc721_native_udt
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc1155_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc1155_user_inventory(
        input: {contract_address: "#{contract_address}"}
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          counts
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
                 "erc1155_user_inventory" => %{"metadata" => %{"total_count" => 6}}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc1155_user_inventory with first page check", %{
    conn: conn,
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address_hash = erc1155_native_udt.contract_address_hash |> to_string()

    query = erc1155_user_inventory_first_page_check_query_base(contract_address_hash, "")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_user_inventory" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc1155_user_inventory_first_page_check_query_base(
        contract_address_hash,
        "after: \"#{after_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_user_inventory" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    # add more one
    _ =
      insert(:current_udt_balance,
        token_contract_address_hash: contract_address_hash,
        token_id: 100,
        value: 1000,
        token_type: :erc1155
      )

    query =
      erc1155_user_inventory_first_page_check_query_base(
        contract_address_hash,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_user_inventory" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc1155_user_inventory_first_page_check_query_base(
        contract_address_hash,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_user_inventory" => %{
          "entries" =>
            [
              %{
                "counts" => "1000"
              }
              | _
            ] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp erc1155_user_inventory_first_page_check_query_base(contract_address, before_or_after) do
    """
    query {
      erc1155_user_inventory(
        input: {
          limit: 2,
          contract_address: "#{contract_address}",
          #{before_or_after}
        }
      ) {
        entries {
          address_hash
          token_contract_address_hash
          token_id
          token_type
          counts
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """
  end

  test "graphql: erc1155_inventory", %{
    conn: conn,
    # user: user
    # erc721_native_udt: erc721_native_udt
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc1155_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc1155_inventory(
        input: { contract_address: "#{contract_address}"}
      ) {
        entries {
          contract_address_hash
          token_id
          counts
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
                 "erc1155_inventory" => %{"metadata" => %{"total_count" => 6}}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc1155_inventory with first page check", %{
    conn: conn,
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address_hash = erc1155_native_udt.contract_address_hash |> to_string()

    query = erc1155_inventory_first_page_check_query_base(contract_address_hash, "")

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_inventory" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc1155_inventory_first_page_check_query_base(
        contract_address_hash,
        "after: \"#{after_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_inventory" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    # add more one
    _ =
      insert(:current_udt_balance,
        token_contract_address_hash: contract_address_hash,
        token_id: 100,
        value: 1000,
        token_type: :erc1155
      )

    query =
      erc1155_inventory_first_page_check_query_base(
        contract_address_hash,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_inventory" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query =
      erc1155_inventory_first_page_check_query_base(
        contract_address_hash,
        "before: \"#{before_value}\""
      )

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "erc1155_inventory" => %{
          "entries" =>
            [
              %{
                "counts" => "1000"
              }
              | _
            ] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp erc1155_inventory_first_page_check_query_base(contract_address, before_or_after) do
    """
    query {
      erc1155_inventory(
        input: {
          contract_address: "#{contract_address}",
          limit: 2,
          #{before_or_after}
        }
      ) {
        entries {
          contract_address_hash
          token_id
          counts
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """
  end

  test "graphql: erc1155_inventory with paginator", %{
    conn: conn,
    # user: user
    # erc721_native_udt: erc721_native_udt
    erc1155_native_udt: erc1155_native_udt
  } do
    contract_address = erc1155_native_udt.contract_address_hash |> to_string()

    query = """
    query {
      erc1155_inventory(
        input: { contract_address: "#{contract_address}", limit: 3}
      ) {
        entries {
          contract_address_hash
          token_id
          counts
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

    %{
      "data" => %{
        "erc1155_inventory" => %{"entries" => entries, "metadata" => %{"after" => after_value}}
      }
    } = json_response(conn, 200)

    assert(length(entries) == 3)

    query = """
    query {
      erc1155_inventory(
        input: { contract_address: "#{contract_address}", limit: 3, after: "#{after_value}"}
      ) {
        entries {
          contract_address_hash
          token_id
          counts
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

    %{
      "data" => %{
        "erc1155_inventory" => %{"entries" => entries, "metadata" => %{"total_count" => 6}}
      }
    } = json_response(conn, 200)

    assert(length(entries) == 3)
  end
end
