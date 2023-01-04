defmodule GodwokenExplorer.Graphql.HistoryTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    native_udt = insert(:native_udt)
    udt = insert(:ckb_udt, bridge_account_id: native_udt.id)
    insert(:ckb_account)
    user = insert(:user)
    block = insert(:block)

    deposit = insert(:deposit_history, script_hash: user.script_hash)

    withdrawal =
      insert(:withdrawal_history,
        l2_script_hash: user.script_hash,
        block_number: block.number,
        block_hash: block.hash
      )

    %{
      deposit: deposit,
      user: user,
      udt: udt,
      withdrawal: withdrawal,
      block: block,
      native_udt: native_udt
    }
  end

  test "graphql: deposit_withdrawal_histories ", %{conn: conn, block: block, udt: udt} do
    number = block.number

    query = """
    query {
      deposit_withdrawal_histories(input: {start_block_number: #{number}}){
        entries{
          block_number
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
                 "deposit_withdrawal_histories" => %{
                   "entries" => [
                     %{"block_number" => ^number}
                   ]
                 }
               }
             },
             json_response(conn, 200)
           )

    udt_id = udt.id

    query = """
    query {
      deposit_withdrawal_histories(input: {udt_id: #{udt_id}}){
        entries{
          block_number
          udt {
            id
          }
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
                 "deposit_withdrawal_histories" => %{
                   "entries" => [
                     %{"udt" => %{"id" => ^udt_id}}
                   ]
                 }
               }
             },
             json_response(conn, 200) |> IO.inspect()
           )
  end
end
