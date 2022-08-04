defmodule GodwokenExplorer.Graphql.LogTest do
  use GodwokenExplorerWeb.ConnCase
  alias GodwokenExplorer.Factory

  setup do
    {:ok, args} =
      GodwokenExplorer.Chain.Data.cast(
        "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000"
      )

    transaction = Factory.build(:transaction, args: args)
    log = Factory.insert!(:log, transaction_hash: transaction.eth_hash)
    [log: log]
  end

  test "graphql: logs ", %{conn: conn, log: log} do
    block_number = log.block_number

    query = """
    query {
      logs(input: {}) {
        transaction_hash
        block_number
        address_hash
        data
        first_topic
        second_topic
        third_topic
        fourth_topic
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
                 "logs" => [
                   %{
                     "block_number" => ^block_number
                   }
                 ]
               }
             },
             json_response(conn, 200)
           )
  end
end
