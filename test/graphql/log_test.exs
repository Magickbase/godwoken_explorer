defmodule GodwokenExplorer.Graphql.LogTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory, only: [insert!: 2, build: 2]

  setup do
    {:ok, args} =
      GodwokenExplorer.Chain.Data.cast(
        "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000"
      )

    transaction = build(:transaction, args: args)
    log = insert!(:log, transaction_hash: transaction.eth_hash)
    udt = insert!(:native_udt, contract_address_hash: log.address_hash)
    [log: log, udt: udt]
  end

  test "graphql: logs ", %{conn: conn, log: log} do
    block_number = log.block_number
    contract_address_hash = log.address_hash |> to_string()

    query = """
    query {
      logs(
        input: { limit: 2, sorter: { sort_type: ASC, sort_value: BLOCK_NUMBER } }
      ) {
        entries {
          transaction_hash
          block_number
          address_hash
          data
          first_topic
          second_topic
          third_topic
          fourth_topic
          udt {
            contract_address_hash
          }
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
                 "logs" => %{
                   "entries" => [
                     %{
                       "block_number" => ^block_number,
                       "udt" => %{
                         "contract_address_hash" => ^contract_address_hash
                       }
                     }
                   ]
                 }
               }
             },
             json_response(conn, 200)
           )
  end
end
