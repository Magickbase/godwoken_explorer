defmodule GodwokenExplorer.Graphql.AccountTest do
  use GodwokenExplorerWeb.ConnCase

  alias GodwokenExplorer.Factory

  setup do
    :ok
  end

  test "graphql: account", %{conn: conn} do
    user = Factory.insert!(:user)

    query = """
    query {
      account(input: {address: "#{user.eth_address}"}) {
        type
        eth_address
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
                 "type" => "ETH_USER"
               }
             }
           }
  end

  test "graphql: account with udt subfield", %{conn: conn} do
    {:ok, script_hash} =
      GodwokenExplorer.Chain.Hash.cast(
        GodwokenExplorer.Chain.Hash.Full,
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      )

    udt = Factory.insert!(:ckb_udt, script_hash: script_hash)
    account = Factory.insert!(:ckb_account)

    query = """
    query {
      account(input: {script_hash: "#{account.script_hash}"}) {
        type
        udt {
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
                 "udt" => %{
                   "id" => udt.id |> to_string(),
                   "name" => udt.name
                 }
               }
             }
           }
  end
end
