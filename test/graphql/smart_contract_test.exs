defmodule GodwokenExplorer.Graphql.SmartContractTest do
  use GodwokenExplorerWeb.ConnCase
  import GodwokenExplorer.Factory, only: [insert!: 1, insert!: 2, insert: 1, insert: 2]

  setup do
    ckb_account = insert(:ckb_account)
    ckb_contract_account = insert(:ckb_contract_account)
    _ = insert(:ckb_udt)
    _ = insert(:ckb_native_udt)

    for _ <- 1..3 do
      _smart_contract = insert(:smart_contract)
    end

    polyjuice_contract_account = insert!(:polyjuice_contract_account)
    smart_contract = insert!(:smart_contract, account: polyjuice_contract_account)

    _cub =
      insert(:current_udt_balance,
        address_hash: smart_contract.account.eth_address,
        token_contract_address_hash: ckb_contract_account.eth_address,
        value: 10000,
        token_type: :erc20
      )

    GodwokenExplorer.Graphql.Workers.UpdateSmartContractCKB.trigger_update_all_smart_contracts_ckbs()

    [
      smart_contract: smart_contract,
      polyjuice_contract_account: polyjuice_contract_account,
      ckb_account: ckb_account,
      ckb_contract_account: ckb_contract_account
    ]
  end

  test "graphql: smart_contract ", %{
    conn: conn,
    smart_contract: smart_contract
    # ckb_account: ckb_account
  } do
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
        ckb_balance
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
                 "smart_contract" => %{"ckb_balance" => "10000"}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: smart_contracts with ckb_balance_sorter", %{conn: conn} do
    query = """
    query {
      smart_contracts(
        input: {
          limit: 5
          sorter: [
            { sort_type: DESC, sort_value: CKB_BALANCE }
            { sort_type: ASC, sort_value: ID }
            { sort_type: ASC, sort_value: NAME }
          ]
        }
      ) {
        entries {
          name
          account_id
          account {
            eth_address
          }
          ckb_balance
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
        "smart_contracts" => %{
          "entries" => [%{"ckb_balance" => "10000"} | _],
          "metadata" => %{
            "total_count" => 4,
            "after" => _after_value
          }
        }
      }
    } = json_response(conn, 200)
  end

  test "graphql: smart_contracts ", %{conn: conn} do
    # paginator with null value of name
    for _ <- 1..3 do
      _smart_contract = insert(:smart_contract, name: nil)
    end

    query = """
    query {
      smart_contracts(
        input: {
          limit: 5
          sorter: [
            { sort_type: ASC, sort_value: ID }
            { sort_type: ASC, sort_value: NAME }
          ]
        }
      ) {
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

    %{
      "data" => %{
        "smart_contracts" => %{
          "entries" => _,
          "metadata" => %{
            "total_count" => 7,
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query = """
    query {
      smart_contracts(
        input: {
          limit: 5
          after: "#{after_value}"
          sorter: [
            { sort_type: ASC, sort_value: ID }
            { sort_type: ASC, sort_value: NAME }
          ]
        }
      ) {
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
                   "entries" => [%{"name" => ""} | _],
                   "metadata" => %{
                     "total_count" => 7
                   }
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: smart_contracts with first page check ", %{conn: conn} do
    query = """
    query {
      smart_contracts(
        input: { limit: 2, sorter: [{ sort_type: DESC, sort_value: ID }] }
      ) {
        entries {
          id
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
        "smart_contracts" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query = smart_contract_with_first_page_check_query(after_value: after_value)

    _smart_contract = insert(:smart_contract)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "smart_contracts" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query = smart_contract_with_first_page_check_query(before_value: before_value)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "smart_contracts" => %{
          "entries" => entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp smart_contract_with_first_page_check_query(before_value: before_value) do
    """
    query {
      smart_contracts(input: {limit: 2, before: "#{before_value}" sorter: [{ sort_type: DESC, sort_value: ID }] }) {
        entries {
          id
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

  defp smart_contract_with_first_page_check_query(after_value: after_value) do
    """
    query {
      smart_contracts(input: {limit: 2, after: "#{after_value}" sorter: [{ sort_type: DESC, sort_value: ID }] }) {
        entries {
          id
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
end
