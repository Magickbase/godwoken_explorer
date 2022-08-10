defmodule GodwokenExplorer.Graphql.SourcifyTest do
  use GodwokenExplorerWeb.ConnCase

  alias GodwokenExplorer.Factory

  setup do
    {:ok, contract_address_hash} =
      GodwokenExplorer.Chain.Hash.cast(
        GodwokenExplorer.Chain.Hash.Address,
        "0x7A4a65Db21864384d2D21a60367d7Fd5c86F8Fba"
      )

    native_udt = Factory.insert!(:native_udt, contract_address_hash: contract_address_hash)

    udt_account =
      Factory.insert!(:polyjuice_contract_account,
        id: native_udt.id,
        eth_address: native_udt.contract_address_hash
      )

    [native_udt: native_udt, udt_account: udt_account]
  end

  test "graphql: sourcify_check_by_addresses  ", %{
    conn: conn
  } do
    query = """
    query {
      sourcify_check_by_addresses(
        input: { addresses: ["0x7A4a65Db21864384d2D21a60367d7Fd5c86F8Fba"] }
      ) {
        address
        status
        chain_ids
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
                 "sourcify_check_by_addresses" => [
                   %{
                     "status" => "perfect"
                   }
                 ]
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: verify_and_update_from_sourcify  ", %{
    conn: conn,
    native_udt: _native_udt,
    udt_account: udt_account
  } do
    query = """
    mutation {
      verify_and_update_from_sourcify(
        input: { address: "0x7A4a65Db21864384d2D21a60367d7Fd5c86F8Fba" }
      ) {
        id
        account_id
        # contract_source_code
        # abi
        compiler_version
        deployment_tx_hash
        name
      }
    }
    """

    udt_account_id = udt_account.id |> to_string()

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "verify_and_update_from_sourcify" => %{
                   "account_id" => ^udt_account_id
                 }
               }
             },
             json_response(conn, 200)
           )
  end
end
