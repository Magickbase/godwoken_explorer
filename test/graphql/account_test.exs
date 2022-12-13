defmodule GodwokenExplorer.Graphql.AccountTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory, only: [insert!: 1, insert!: 2]

  setup do
    {:ok, script_hash} =
      GodwokenExplorer.Chain.Hash.cast(
        GodwokenExplorer.Chain.Hash.Full,
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      )

    native_udt = insert!(:native_udt)

    ckb_udt = insert!(:ckb_udt, script_hash: script_hash, bridge_account_id: native_udt.id)

    ckb_account = insert!(:ckb_account, script_hash: script_hash)
    [native_udt: native_udt, ckb_udt: ckb_udt, ckb_account: ckb_account]
  end

  test "graphql: account api with subfield udt and bridged_udt ", %{
    conn: conn,
    ckb_account: ckb_account,
    native_udt: native_udt,
    ckb_udt: ckb_udt
  } do
    script_hash = ckb_account.script_hash |> to_string()

    query = """
    query {
      account(
        input: {
          script_hash: "#{script_hash}"
        }
      ) {
        udt {
          id
          name
          bridge_account_id
          type
        }
        bridged_udt {
          id
          name
          bridge_account_id
          type
        }
      }
    }
    """

    native_udt_id = native_udt.id
    ckb_udt_id = ckb_udt.id

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "account" => %{
                   "udt" => %{"id" => ^native_udt_id},
                   "bridged_udt" => %{"id" => ^ckb_udt_id}
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: account", %{conn: conn} do
    user = insert!(:user)

    query = """
    query {
      account(input: {address: "#{user.eth_address}"}) {
        type
        eth_address
        bit_alias
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
               "account" => %{
                 "eth_address" => user.eth_address |> to_string(),
                 "type" => "ETH_USER",
                 "bit_alias" => user.bit_alias
               }
             }
           }
  end

  test "graphql: account with udt subfield", %{
    conn: conn,
    ckb_udt: ckb_udt,
    ckb_account: ckb_account
  } do
    query = """
    query {
      account(input: {script_hash: "#{ckb_account.script_hash}"}) {
        type
        bridged_udt {
          id
          name
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
               "account" => %{
                 "type" => "UDT",
                 "bridged_udt" => %{
                   "id" => ckb_udt.id,
                   "name" => ckb_udt.display_name
                 }
               }
             }
           }
  end
end
