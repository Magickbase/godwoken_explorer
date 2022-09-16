defmodule GodwokenExplorer.Graphql.AccountUDTTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory, only: [insert!: 1, insert!: 2]

  setup do
    {:ok, script_hash} =
      GodwokenExplorer.Chain.Hash.cast(
        GodwokenExplorer.Chain.Hash.Full,
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      )

    native_udt = insert!(:native_udt)

    _native_account =
      insert!(:polyjuice_contract_account,
        eth_address: native_udt.contract_address_hash,
        id: native_udt.id
      )

    ckb_account = insert!(:ckb_account, script_hash: script_hash)

    ckb_udt =
      insert!(:ckb_udt,
        id: ckb_account.id,
        script_hash: script_hash,
        bridge_account_id: native_udt.id
      )

    user = insert!(:user)

    # base_t = DateTime.utc_now()
    # inc_base_t = DateTime.add(base_t, 100, :day)
    # fetch_base_t = DateTime.add(base_t, -100, :day)

    base_t = ~U[2022-09-07 10:34:14.021000Z]
    inc_base_t = ~U[2022-09-16 02:56:57.629000Z]
    fetch_base_t = ~U[2022-07-25 07:53:57.788000Z]

    cub =
      insert!(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: native_udt.contract_address_hash,
        value: 10000,
        token_type: :erc20,
        updated_at: inc_base_t,
        value_fetched_at: fetch_base_t
      )

    cbub =
      insert!(:current_bridged_udt_balance,
        address_hash: cub.address_hash,
        value: 20000,
        udt_id: ckb_udt.id,
        udt_script_hash: ckb_udt.script_hash,
        updated_at: base_t
      )

    [
      user: user,
      native_udt: native_udt,
      ckb_udt: ckb_udt,
      ckb_account: ckb_account,
      cub: cub,
      cbub: cbub
    ]
  end

  test "graphql: account_udts with native and bridge token", %{conn: conn, cub: cub, cbub: cbub} do
    address = cbub.address_hash |> to_string()
    token_contract_address_hash = cub.token_contract_address_hash |> to_string()

    query = """
    query {
      account_udts(
        input: {
          address_hashes: ["#{address}"],
          token_contract_address_hash: "#{token_contract_address_hash}"
        }
      ) {
        value
        uniq_id
        udt {
          id
          type
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
                 "account_udts" => [
                   %{"value" => "20000"},
                   %{"value" => "20000"}
                 ]
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: account_current_udts ", %{conn: conn, cub: cub} do
    address = cub.address_hash |> to_string()
    token_contract_address_hash = cub.token_contract_address_hash |> to_string()

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

    assert match?(
             %{
               "data" => %{
                 "account_current_udts" => [
                   %{"token_contract_address_hash" => ^token_contract_address_hash}
                 ]
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: account_current_bridged_udts ", %{conn: conn, cbub: cbub} do
    address = cbub.address_hash |> to_string()
    udt_script_hash = cbub.udt_script_hash |> to_string()

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

    assert match?(
             %{
               "data" => %{
                 "account_current_bridged_udts" => [%{"udt_script_hash" => ^udt_script_hash}]
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: account_udts only with address_hashes", %{conn: conn, cbub: cbub} do
    address = cbub.address_hash |> to_string()

    query = """
    query {
      account_udts(
        input: {
          address_hashes: ["#{address}"]
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

    assert match?(
             %{
               "data" => %{
                 "account_udts" => [%{"value" => "20000"}, %{"value" => "20000"}]
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: account_udts with script hash ", %{conn: conn, cbub: cbub} do
    address = cbub.address_hash |> to_string()
    udt_script_hash = cbub.udt_script_hash |> to_string()

    query = """
    query {
      account_udts(
        input: {
          address_hashes: ["#{address}"]
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

    assert match?(
             %{
               "data" => %{
                 "account_udts" => [%{"value" => "20000"}, %{"value" => "20000"}]
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: account_udts with contract address hash ", %{conn: conn, cub: cub} do
    address = cub.address_hash |> to_string()
    token_contract_address_hash = cub.token_contract_address_hash |> to_string()

    query = """
    query {
      account_udts(
        input: {
          address_hashes: ["#{address}"]
          token_contract_address_hash: "#{token_contract_address_hash}"
        }
      ) {
        token_contract_address_hash
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

    assert match?(
             %{
               "data" => %{
                 "account_udts" => [%{"value" => "20000"}, %{"value" => "20000"}]
               }
             },
             json_response(conn, 200)
           )
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

    assert match?(
             %{
               "data" => %{
                 "account_ckbs" => [
                   %{
                     "value" => "20000"
                   }
                 ]
               }
             },
             json_response(conn, 200)
           )
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
