defmodule GodwokenExplorer.Graphql.LogTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory, only: [insert!: 2, insert: 2]

  setup do
    {:ok, args} =
      GodwokenExplorer.Chain.Data.cast(
        "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000"
      )

    transaction = insert(:transaction, args: args)

    log = insert(:log, transaction_hash: transaction.eth_hash)
    udt = insert(:native_udt, contract_address_hash: log.address_hash)

    polyjuice_contract_account =
      insert!(:polyjuice_contract_account, eth_address: log.address_hash)

    smart_contract = insert(:smart_contract, account: polyjuice_contract_account)
    [log: log, udt: udt, smart_contract: smart_contract]
  end

  test "graphql: logs ", %{conn: conn, log: log, smart_contract: smart_contract} do
    block_number = log.block_number
    contract_address_hash = log.address_hash |> to_string()
    account_id = smart_contract.account_id

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
          smart_contract {
            id
            account_id
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
                       },
                       "smart_contract" => %{
                         "account_id" => ^account_id
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
