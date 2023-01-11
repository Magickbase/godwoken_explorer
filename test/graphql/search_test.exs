defmodule GodwokenExplorer.Graphql.SearchTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory, only: [insert: 1, insert: 2, insert!: 1]
  import Mock

  setup do
    for _ <- 1..10 do
      insert(:native_udt, eth_type: :erc721)
      insert(:native_udt, eth_type: :erc1155)
    end

    second_last_udt = insert(:native_udt, eth_type: :erc721)
    last_udt = insert(:native_udt, eth_type: :erc1155)

    [second_last_udt: second_last_udt, last_udt: last_udt]
  end

  test "graphql: search_keyword with udt", %{conn: conn} do
    # exact matching
    name = "SSS_UDT"
    fuzzy_name = "%UDT%"
    insert(:native_udt, eth_type: :erc721, name: name)
    insert(:native_udt, eth_type: :erc1155)

    query = search_keyword(name)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "search_keyword" => %{
                   "type" => "UDT"
                 }
               }
             },
             json_response(conn, 200)
           )

    # more than one matching
    query = search_keyword(fuzzy_name)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "search_keyword" => nil
               },
               "errors" => _
             },
             json_response(conn, 200)
           )

    ## polyjuice contract account
    account = insert!(:polyjuice_contract_account)
    keyword = to_string(account.eth_address)
    query = search_keyword(keyword)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "search_keyword" => %{
                   "type" => "ACCOUNT"
                 }
               }
             },
             json_response(conn, 200)
           )

    ## not exist address
    keyword = "0xbFbE23681D99A158f632e64A31288946770c7A9e"
    query = search_keyword(keyword)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "search_keyword" => %{
                   "type" => "ADDRESS"
                 }
               }
             },
             json_response(conn, 200)
           )

    block = insert(:block)
    from_account = insert!(:user)
    to_account = insert!(:polyjuice_contract_account)

    transaction =
      insert(:transaction,
        from_account: from_account,
        to_account: to_account,
        block: block,
        block_number: block.number
      )

    ## test block keyword
    keyword = block.number |> to_string()
    query = search_keyword(keyword)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "search_keyword" => %{
                   "type" => "BLOCK"
                 }
               }
             },
             json_response(conn, 200)
           )

    ## test transaction keyword
    keyword = transaction.hash |> to_string()
    query = search_keyword(keyword)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "search_keyword" => %{
                   "type" => "TRANSACTION"
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  defp search_keyword(keyword) do
    """
    query {
      search_keyword(input: { keyword: "#{keyword}"}){
        type
        id
      }
    }
    """
  end

  test "graphql: search_udt ", %{conn: conn} do
    fuzzy_name = "%UD%"

    query = """
    query {
      search_udt(input: { fuzzy_name: "#{fuzzy_name}", limit: 1 }) {
        entries {
          id
          icon
          name
          symbol
          type
          eth_type
          contract_address_hash
        }
        metadata {
          total_count
          before
          after
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
                 "search_udt" => %{
                   "entries" => [%{"name" => "UDT" <> _}],
                   "metadata" => %{"total_count" => 22}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: search_udt with paginator", %{conn: conn, second_last_udt: second_last_udt} do
    fuzzy_name = "%UD%"

    query = """
    query {
      search_udt(input: { fuzzy_name: "#{fuzzy_name}", limit: 1 }) {
        entries {
          id
          icon
          name
          symbol
          type
          eth_type
          contract_address_hash
        }
        metadata {
          total_count
          before
          after
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
        "search_udt" => %{
          "entries" => _,
          "metadata" => %{"after" => after_value}
        }
      }
    } = json_response(conn, 200)

    query = """
    query {
      search_udt(input: { fuzzy_name: "#{fuzzy_name}", limit: 1, after: "#{after_value}"}) {
        entries {
          id
          icon
          name
          symbol
          type
          eth_type
          contract_address_hash
        }
        metadata {
          total_count
          before
          after
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    second_last_udt_id = second_last_udt.id

    assert match?(
             %{
               "data" => %{
                 "search_udt" => %{
                   "entries" => [%{"id" => ^second_last_udt_id, "name" => "UDT" <> _}],
                   "metadata" => %{"total_count" => 22}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  describe "bit alias" do
    test "query with wrong format alias", %{conn: conn} do
      query = """
      query{
        search_bit_alias(
          input: {
            bit_alias: "freder"
          }
        )
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
                   "search_bit_alias" => nil
                 },
                 "errors" => _
               },
               json_response(conn, 200)
             )
    end

    test "query with correct format alias", %{conn: conn} do
      query = """
      query{
        search_bit_alias(
          input: {
            bit_alias: "freder.bit"
          }
        )
      }
      """

      with_mock GodwokenExplorer.Bit.API,
        fetch_address_by_alias: fn _bit_alias ->
          {:ok, "0xcc0af0af911dd40853b8c8dfee90b32f8d1ecad6"}
        end do
        conn =
          post(conn, "/graphql", %{
            "query" => query,
            "variables" => %{}
          })

        assert json_response(conn, 200) == %{
                 "data" => %{
                   "search_bit_alias" => "0xcc0af0af911dd40853b8c8dfee90b32f8d1ecad6"
                 }
               }
      end
    end
  end
end
