defmodule GodwokenExplorer.Graphql.SmartContractTest do
  use GodwokenExplorerWeb.ConnCase
  import GodwokenExplorer.Factory, only: [insert!: 1, insert!: 2, insert: 1, insert: 2]

  setup do
    ckb_account = insert(:ckb_account)
    ckb_contract_account = insert(:ckb_contract_account)
    _ = insert(:ckb_udt)
    _ = insert(:ckb_native_udt)
    polyjuice_contract_account = insert!(:polyjuice_contract_account)
    smart_contract = insert!(:smart_contract, account: polyjuice_contract_account)

    _cub =
      insert(:current_udt_balance,
        address_hash: smart_contract.account.eth_address,
        token_contract_address_hash: ckb_contract_account.eth_address,
        value: 10000,
        token_type: :erc20
      )

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
                   "entries" => _,
                   "metadata" => %{
                     "total_count" => 1
                   }
                 }
               }
             },
             json_response(conn, 200)
           )
  end
end
