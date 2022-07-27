defmodule GodwokenExplorer.Graphql.AccountUDTTest do
  use GodwokenExplorerWeb.ConnCase

  alias GodwokenExplorer.Factory

  setup do
    {:ok, script_hash} =
      GodwokenExplorer.Chain.Hash.cast(
        GodwokenExplorer.Chain.Hash.Full,
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      )

    ckb_udt = Factory.insert!(:ckb_udt, script_hash: script_hash)

    ckb_account = Factory.insert!(:ckb_account, script_hash: script_hash)

    cub = Factory.insert!(:current_udt_balance, value: Enum.random(1..100_000))

    cbub =
      Factory.insert!(:current_bridged_udt_balance,
        value: Enum.random(1..100_000),
        udt_id: ckb_udt.id,
        udt_script_hash: ckb_udt.script_hash
      )

    [ckb_udt: ckb_udt, ckb_account: ckb_account, cub: cub, cbub: cbub]
  end

  test "graphql: account_current_udts ", %{conn: conn, cub: cub} do
    address = cub.address_hash |> to_string()

    query = """
    query {
      account_current_udts(input: { address_hashes: ["#{address}"] }) {
        block_number
        id
        token_contract_address_hash
        value
        value_fetched_at
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) == %{
             "data" => %{
               "account_current_udts" => []
             }
           }
  end

  test "graphql: account_current_bridged_udts ", %{conn: conn, cbub: cbub} do
    address = cbub.address_hash |> to_string()

    query = """
    query {
      account_current_bridged_udts(
        input: {
          address_hashes: ["#{address}"]
        }
      ) {
        block_number
        id
        udt_script_hash
        value
        value_fetched_at
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) == %{
             "data" => %{
               "account_current_bridged_udts" => []
             }
           }
  end

  test "graphql: account_udts ", %{conn: conn, cbub: cbub} do
    address = cbub.address_hash |> to_string()
    udt_script_hash = cbub.udt_script_hash |> to_string()

    query = """
    query {
      account_udts(
        input: {
          address_hashes: ["#{address}"],

          udt_script_hash: "#{udt_script_hash}"
        }
      ) {
        udt_script_hash
        value
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) == %{
             "data" => %{
               "account_udts" => []
             }
           }
  end

  test "graphql: account_ckbs ", %{conn: conn, cbub: cbub} do
    address = cbub.address_hash |> to_string()
    # udt_script_hash = cbub.udt_script_hash |> to_string()

    query = """
    query {
      account_ckbs(
        input: { address_hashes: ["#{address}"] }
      ) {
        udt_script_hash
        value
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) == %{
             "data" => %{
               "account_ckbs" => []
             }
           }
  end

  test "graphql: account_udts_by_contract_address ", %{conn: conn, cub: cub} do
    # address = cub.address_hash |> to_string()
    token_contract_address_hash = cub.token_contract_address_hash |> to_string()

    query = """
    query {
      account_udts_by_contract_address(
        input: {
          token_contract_address_hash: "#{token_contract_address_hash}"
          sort_type: ASC
          page_size: 1
        }
      ) {
        block_number
        id
        token_contract_address_hash
        value
        value_fetched_at
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
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
                 "account_udts_by_contract_address" => [
                   %{
                     "token_contract_address_hash" => ^token_contract_address_hash
                   }
                 ]
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: account_bridged_udts_by_script_hash ", %{conn: conn, cbub: cbub} do
    # address = cbub.address_hash |> to_string()
    udt_script_hash = cbub.udt_script_hash |> to_string()

    query = """
    query {
      account_bridged_udts_by_script_hash(
        input: {
          udt_script_hash: "#{udt_script_hash}"
          sort_type: ASC
          page_size: 1
        }
      ) {
        block_number
        id
        udt_script_hash
        value
        value_fetched_at
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
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
                 "account_bridged_udts_by_script_hash" => [
                   %{
                     "udt_script_hash" => ^udt_script_hash
                   }
                 ]
               }
             },
             json_response(conn, 200)
           )
  end
end
