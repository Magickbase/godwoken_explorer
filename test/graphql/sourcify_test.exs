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

    unregistered_udt_account = Factory.insert!(:polyjuice_contract_account)

    {:ok, args} =
      GodwokenExplorer.Chain.Data.cast(
        "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000"
      )

    transaction = Factory.insert!(:transaction, args: args)

    _polyjuice =
      Factory.insert!(:polyjuice,
        created_contract_address_hash: unregistered_udt_account.eth_address,
        transaction: transaction
      )

    [
      native_udt: native_udt,
      udt_account: udt_account,
      unregistered_udt_account: unregistered_udt_account,
      transaction: transaction
    ]
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

  test "graphql: verify_and_update_from_sourcify unregistered ", %{
    conn: conn,
    unregistered_udt_account: unregistered_udt_account,
    transaction: transaction
  } do
    address = unregistered_udt_account.eth_address |> to_string()
    unregistered_udt_account_id = unregistered_udt_account.id |> to_string()
    deployment_tx_hash = transaction.eth_hash |> to_string()

    query = """
    mutation {
      verify_and_update_from_sourcify(
        input: { address: "#{address}" }
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

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "verify_and_update_from_sourcify" => %{
                   "account_id" => ^unregistered_udt_account_id,
                   "deployment_tx_hash" => ^deployment_tx_hash
                 }
               }
             },
             json_response(conn, 200)
           )
  end
end
