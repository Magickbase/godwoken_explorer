defmodule GodwokenExplorer.Graphql.TransactionTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory, only: [insert: 1, insert: 2, insert!: 1, insert!: 2]

  setup do
    {:ok, args} =
      GodwokenExplorer.Chain.Data.cast(
        "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000"
      )

    block = insert(:block)

    transaction = insert!(:transaction, args: args, block: block, block_number: block.number)
    _transaction2 = insert!(:transaction, args: args, block: block, block_number: block.number)
    _transaction3 = insert!(:transaction, args: args)

    [transaction: transaction, block: block]
  end

  test "graphql: transaction ", %{conn: conn, transaction: transaction} do
    eth_hash = transaction.eth_hash |> to_string()

    query = """
    query {
        transaction(
          input: {
            eth_hash: "#{eth_hash}"
          }
        ) {
          hash
          nonce
          type
          index
          from_account {
            eth_address
            type
          }
          to_account {
            eth_address
            type
          }
          polyjuice {
            is_create
            value
            status
            input
            created_contract_address_hash
            gas_used
            gas_limit
            gas_price
          }
          block {
            number
            hash
            timestamp
            status
            layer1_block_number
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
                 "transaction" => %{}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: transactions ", %{conn: conn, transaction: _transaction} do
    query = """
    query {
      transactions(
        input: {
          limit: 1
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: HASH }
            { sort_type: ASC, sort_value: INDEX }
          ]
        }
      ) {
        entries {
          hash
          eth_hash
          block_hash
          block_number
          type
          from_account_id
          from_account {
            script_hash
            id
            eth_address
          }
          to_account_id
        }

        metadata {
          total_count
          before
          after
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
                 "transactions" => %{
                   "entries" => _,
                   "metadata" => %{
                     "total_count" => 3
                   }
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: transactions with paginator", %{
    conn: conn,
    block: block,
    transaction: _transaction
  } do
    block_number = block.number

    query = """
    query {
      transactions(
        input: {
          limit: 1
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
          ]
        }
      ) {
        entries {
          hash
          eth_hash
          block_hash
          block_number
          type
          from_account_id
          from_account {
            script_hash
            id
            eth_address
          }
          to_account_id
        }

        metadata {
          total_count
          before
          after
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
        "transactions" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    assert match?(
             %{
               "data" => %{
                 "transactions" => %{
                   "entries" => [%{"block_number" => ^block_number}],
                   "metadata" => %{
                     "total_count" => 3
                   }
                 }
               }
             },
             json_response(conn, 200)
           )

    query = """
    query {
      transactions(
        input: {
          limit: 1
          after: "#{after_value}"
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
          ]
        }
      ) {
        entries {
          hash
          eth_hash
          block_hash
          block_number
          type
          from_account_id
          from_account {
            script_hash
            id
            eth_address
          }
          to_account_id
        }

        metadata {
          total_count
          before
          after
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
                 "transactions" => %{
                   "entries" => [%{"block_number" => ^block_number}],
                   "metadata" => %{
                     "total_count" => 3
                   }
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: transactions with method id and method name", %{
    conn: conn
  } do
    user = insert!(:user)
    contract = insert!(:polyjuice_contract_account)

    _udt =
      insert!(:native_udt,
        id: contract.id,
        type: :native,
        name: "CKB",
        symbol: "CKB",
        decimal: 8,
        contract_address_hash: contract.eth_address
      )

    block = insert!(:block)

    transaction =
      :transaction
      |> insert(
        from_account: user,
        to_account: contract,
        block_number: block.number,
        block: block,
        method_id: "0x12345678"
      )

    polyjuice = insert(:polyjuice, transaction: transaction, input: "0x12345678")

    input = polyjuice.input |> to_string()
    method_id = String.slice(input, 0, 10)

    eth_hash = transaction.eth_hash |> to_string()

    query = """
    query {
      transaction(
        input: {
          eth_hash: "#{eth_hash}"
        }
      ) {
        method_id
        method_name
        polyjuice {
          input
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
                 "transaction" => %{
                   "method_id" => ^method_id
                 }
               }
             },
             json_response(conn, 200)
           )

    query = """
    query {
      transactions(
        input: {
           method_id: "0x12345678"
        }
      ) {
        entries {
          method_id
          method_name
          polyjuice {
            input
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
                 "transactions" => %{
                   "entries" => [
                     %{
                       "method_id" => "0x12345678",
                       "method_name" => nil,
                       "polyjuice" => %{"input" => "0x12345678"}
                     }
                   ]
                 }
               }
             },
             json_response(conn, 200)
           )

    ## input with "0x00"
    transaction =
      :transaction
      |> insert(
        from_account: user,
        to_account: contract,
        block_number: block.number,
        block: block
      )

    eth_hash = transaction.eth_hash |> to_string()
    _polyjuice = insert(:polyjuice, transaction: transaction, input: "0x00")

    query = """
    query {
      transaction(
        input: {
          eth_hash: "#{eth_hash}"
        }
      ) {
        method_id
        method_name
        polyjuice {
          input
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
                 "transaction" => %{
                   "method_id" => nil
                 }
               }
             },
             json_response(conn, 200)
           )

    ## not polyjuice transaction
    transaction = insert(:polyjuice_creator_tx)
    transaction_hash = transaction.hash |> to_string()
    _polyjuice = insert(:polyjuice, transaction: transaction, input: "0x12345678")

    query = """
    query {
      transaction(
        input: {
          transaction_hash: "#{transaction_hash}"
        }
      ) {
        method_id
        method_name
        polyjuice {
          input
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
                 "transaction" => %{
                   "method_id" => nil
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "pending transaction", %{conn: conn} do
    pending_tx = insert(:pending_transaction)

    query = """
    query {
      transactions(
        input: {
          status: PENDING
        }
      ) {
        entries {
          hash
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "transactions" => %{
                   "entries" => [%{"hash" => pending_tx.hash |> to_string()}]
                 }
               }
             }
  end

  test "show polyjuice creator tx by hash", %{
    conn: conn
  } do
    block = insert(:block)
    eth_user = insert(:user)

    created_account =
      insert(:user,
        script_hash: "0x76e09f2071a91828df82ceb8e97486ed680130ddd8cefbe4298a43d0037feac3",
        eth_address: "0x48a466ed98a517bab6158209bd54c6b29281b733"
      )

    polyjuice_creator_tx =
      insert(:polyjuice_creator_tx,
        from_account: eth_user,
        block: block,
        block_number: block.number,
        index: 0
      )

    insert(:polyjuice_creator, transaction: polyjuice_creator_tx)

    query = """
    query {
      transaction(
        input: {
          transaction_hash: "#{polyjuice_creator_tx.hash |> to_string()}"
        }
      ) {
          polyjuice_creator {
            created_account {
              eth_address
              type
              script_hash
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

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "transaction" => %{
                   "polyjuice_creator" => %{
                     "created_account" => %{
                       "eth_address" => created_account.eth_address |> to_string(),
                       "type" => "ETH_USER",
                       "script_hash" => created_account.script_hash |> to_string()
                     }
                   }
                 }
               }
             }
  end

  test "native transfer transaction", %{conn: conn} do
    block = insert(:block)
    eth_user = insert(:user)
    polyjuice_creator_account = insert(:polyjuice_creator_account)
    receiver_user = insert(:user)

    native_transfer_tx =
      insert(:transaction,
        block: block,
        block_number: block.number,
        from_account: eth_user,
        to_account: polyjuice_creator_account,
        index: 2,
        args:
          "0xffffff504f4c590068bf00000000000000a007c2da51000000000000000000000000e867ce97461d310000000000000000000000715ab282b873b79a7be8b0e8c13c4e8966a52040"
      )

    insert(:polyjuice,
      transaction: native_transfer_tx,
      native_transfer_address_hash: receiver_user.eth_address
    )

    query = """
    query {
      transactions(
        input: {
          from_eth_address: "#{receiver_user.eth_address |> to_string()}",
          to_eth_address: "#{receiver_user.eth_address |> to_string()}"
        }
      ) {
        entries {
          hash
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "transactions" => %{
                   "entries" => [%{"hash" => native_transfer_tx.hash |> to_string()}]
                 }
               }
             }
  end
end
