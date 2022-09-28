defmodule GodwokenExplorer.Graphql.TokenTransferTest do
  use GodwokenExplorerWeb.ConnCase
  import GodwokenExplorer.Factory, only: [insert!: 1, insert!: 2]

  setup do
    {:ok, args} =
      GodwokenExplorer.Chain.Data.cast(
        "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000"
      )

    block = insert!(:block)
    transaction = insert!(:transaction, args: args)
    transaction721 = insert!(:transaction, args: args)
    transaction1155 = insert!(:transaction, args: args)

    {:ok, from_address_hash} =
      GodwokenExplorer.Chain.Hash.Address.cast("0x297ce8d1532704f7be447bc897ab63563d60f223")

    {:ok, to_address_hash} =
      GodwokenExplorer.Chain.Hash.Address.cast("0xf00b259ed79bb80291b45a76b13e3d71d4869433")

    {:ok, token_contract_address_hash} =
      GodwokenExplorer.Chain.Hash.Address.cast("0xb02c930c2825a960a50ba4ab005e8264498b64a0")

    insert!(:native_udt,
      eth_type: :erc20,
      contract_address_hash: token_contract_address_hash
    )

    {:ok, erc721_token_contract_address_hash} =
      GodwokenExplorer.Chain.Hash.Address.cast("0x721c930c2825a960a50ba4ab005e8264488b64a0")

    insert!(:native_udt,
      eth_type: :erc721,
      contract_address_hash: erc721_token_contract_address_hash
    )

    {:ok, erc1155_token_contract_address_hash} =
      GodwokenExplorer.Chain.Hash.Address.cast("0x1155930c2825a960a50ba4ab005e8264488b64a0")

    insert!(:native_udt,
      eth_type: :erc1155,
      contract_address_hash: erc1155_token_contract_address_hash
    )

    token_transfer =
      insert!(:token_transfer,
        transaction: transaction,
        block: block,
        from_address_hash: from_address_hash,
        to_address_hash: to_address_hash,
        token_contract_address_hash: token_contract_address_hash
      )

    erc721_token_transfer =
      insert!(:token_transfer,
        transaction: transaction721,
        block: block,
        from_address_hash: from_address_hash,
        to_address_hash: to_address_hash,
        token_contract_address_hash: erc721_token_contract_address_hash,
        token_id: 1
      )

    _erc1155_token_transfer =
      insert!(:token_transfer,
        transaction: transaction1155,
        block: block,
        from_address_hash: from_address_hash,
        to_address_hash: to_address_hash,
        token_contract_address_hash: erc1155_token_contract_address_hash,
        token_ids: [2, 3],
        log_index: 1
      )

    _erc1155_token_transfer =
      insert!(:token_transfer,
        transaction: transaction1155,
        block: block,
        from_address_hash: from_address_hash,
        to_address_hash: to_address_hash,
        token_contract_address_hash: erc1155_token_contract_address_hash,
        token_id: 1,
        log_index: 2
      )

    [token_transfer: token_transfer, erc721_token_transfer: erc721_token_transfer, block: block]
  end

  test "graphql: erc1155 token_transfers ", %{conn: conn, token_transfer: _token_transfer} do
    query = """
    query {
      erc1155_token_transfers(
        input: {
          limit: 2
          combine_from_to: true
          token_contract_address_hash: "0x1155930c2825a960a50ba4ab005e8264488b64a0"
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          transaction_hash
          token_id
          token_ids
          block_number
          to_account {
            eth_address
          }
          to_address
          from_account {
            eth_address
          }
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
                 "erc1155_token_transfers" => %{
                   "entries" => _,
                   "metadata" => %{
                     "total_count" => 2
                   }
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: erc1155 token_transfers with token id", %{
    conn: conn,
    token_transfer: _token_transfer
  } do
    query = """
    query {
      erc1155_token_transfers(
        input: {
          limit: 2
          token_id: 1
          token_contract_address_hash: "0x1155930c2825a960a50ba4ab005e8264488b64a0"
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          transaction_hash
          token_id
          token_ids
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
                 "erc1155_token_transfers" => %{
                   "entries" => _,
                   "metadata" => %{
                     "total_count" => 1
                   }
                 }
               }
             },
             json_response(conn, 200)
           )

    query = """
    query {
      erc1155_token_transfers(
        input: {
          limit: 2
          combine_from_to: true
          token_id: 2
          token_contract_address_hash: "0x1155930c2825a960a50ba4ab005e8264488b64a0"
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          transaction_hash
          token_id
          token_ids
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
                 "erc1155_token_transfers" => %{
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

  test "graphql: erc721 token_transfers ", %{conn: conn, token_transfer: _token_transfer} do
    query = """
    query {
      erc721_token_transfers(
        input: {
          limit: 2
          combine_from_to: true
          token_contract_address_hash: "0x721c930c2825a960a50ba4ab005e8264488b64a0"
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          transaction_hash
          token_id
          token_ids
          block_number
          to_account {
            eth_address
          }
          to_address
          from_account {
            eth_address
          }
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
                 "erc721_token_transfers" => %{
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

  test "graphql: erc721 token_transfers with token id ", %{
    conn: conn,
    token_transfer: _token_transfer
  } do
    query = """
    query {
      erc721_token_transfers(
        input: {
          limit: 2
          token_id: 1
          combine_from_to: true
          token_contract_address_hash: "0x721c930c2825a960a50ba4ab005e8264488b64a0"
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          transaction_hash
          token_id
          token_ids
          block_number
          to_account {
            eth_address
          }
          to_address
          from_account {
            eth_address
          }
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
                 "erc721_token_transfers" => %{
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

  test "graphql: token_transfers ", %{conn: conn, token_transfer: _token_transfer} do
    query = """
    query {
      token_transfers(
        input: {
          limit: 2
          combine_from_to: true

          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          transaction_hash
          block_number
          to_account {
            eth_address
          }
          to_address
          from_account {
            eth_address
          }
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
                 "token_transfers" => %{
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

  test "graphql: token_transfers with null input field ", %{
    conn: conn,
    token_transfer: _token_transfer
  } do
    query = """
    query {
      token_transfers(
        input: {
          token_contract_address_hash: null
          limit: 1
        }
      ) {
        entries {
          amount
          transaction_hash
          log_index
          polyjuice {
            status
          }
          from_address
          to_address
          block {
            number
            timestamp
            status
          }
          udt {
            id
            decimal
            symbol
          }
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
                 "token_transfers" => %{
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
