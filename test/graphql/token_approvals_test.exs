defmodule GodwokenExplorer.Graphql.TokenApprovalsTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    user = insert(:user)
    erc20 = insert(:native_udt)
    block = insert(:block)

    approval =
      insert(:approval_token_approval,
        token_owner_address_hash: user.eth_address,
        token_contract_address_hash: erc20.contract_address_hash,
        block_hash: block.hash,
        block_number: block.number
      )

    approval_all =
      insert(:approval_all_token_approval,
        token_owner_address_hash: user.eth_address,
        token_contract_address_hash: erc20.contract_address_hash,
        block_hash: block.hash,
        block_number: block.number
      )

    %{approval: approval, approval_all: approval_all, block: block, erc20: erc20, user: user}
  end

  test "graphql: token_approvals ", %{
    conn: conn,
    approval: approval,
    approval_all: approval_all,
    block: block,
    erc20: erc20
  } do
    address = approval.token_owner_address_hash |> to_string()

    query = """
    query {
     token_approvals(
        input: {
          address: "#{address}"
          token_type: ERC20
          sorter: [
            { sort_type: DESC, sort_value: BLOCK_NUMBER },
            { sort_type: DESC, sort_value: ID }
          ]
        }
     ) {
        entries {
          transaction_hash
          udt {
            id
            name
            eth_type
          }
          block {
            timestamp
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

    response = json_response(conn, 200)

    assert response ==
             %{
               "data" => %{
                 "token_approvals" => %{
                   "entries" => [
                     %{
                       "block" => %{"timestamp" => block.timestamp |> DateTime.to_iso8601()},
                       "transaction_hash" => approval_all.transaction_hash |> to_string(),
                       "udt" => %{"eth_type" => "ERC20", "id" => erc20.id, "name" => erc20.name}
                     },
                     %{
                       "block" => %{"timestamp" => block.timestamp |> DateTime.to_iso8601()},
                       "transaction_hash" => approval.transaction_hash |> to_string(),
                       "udt" => %{"eth_type" => "ERC20", "id" => erc20.id, "name" => erc20.name}
                     }
                   ],
                   "metadata" => %{"after" => nil, "before" => nil, "total_count" => 2}
                 }
               }
             }
  end

  test "graphql: token_approvals with first page check ", %{
    conn: conn,
    user: user,
    erc20: erc20
  } do
    address = user.eth_address |> to_string()

    for _ <- 1..3 do
      insert(:approval_token_approval,
        token_owner_address_hash: user.eth_address,
        token_contract_address_hash: erc20.contract_address_hash
      )
    end

    query = """
    query {
     token_approvals(
        input: {
          address: "#{address}"
          token_type: ERC20
          limit: 2
          sorter: [
            { sort_type: DESC, sort_value: BLOCK_NUMBER },
            { sort_type: DESC, sort_value: ID }
          ]
        }
     ) {
        entries {
          transaction_hash
          block_number
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
        "token_approvals" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query = token_approvals_with_first_page_query(address, after_value: after_value)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "token_approvals" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    %{block_number: newest_block_number} =
      insert(:approval_token_approval,
        token_owner_address_hash: user.eth_address,
        token_contract_address_hash: erc20.contract_address_hash
      )

    query = token_approvals_with_first_page_query(address, before_value: before_value)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "token_approvals" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query = token_approvals_with_first_page_query(address, before_value: before_value)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "token_approvals" => %{
          "entries" => [%{"block_number" => ^newest_block_number} | _] = entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp token_approvals_with_first_page_query(address, before_value: before_value) do
    """
    query {
     token_approvals(
        input: {
          before: "#{before_value}"
          address: "#{address}"
          token_type: ERC20
          limit: 2
          sorter: [
            { sort_type: DESC, sort_value: BLOCK_NUMBER },
            { sort_type: DESC, sort_value: ID }
          ]
        }
     ) {
        entries {
          transaction_hash
          block_number
        }

        metadata {
          total_count
          before
          after
        }
      }
    }
    """
  end

  defp token_approvals_with_first_page_query(address, after_value: after_value) do
    """
    query {
     token_approvals(
        input: {
          after: "#{after_value}"
          address: "#{address}"
          token_type: ERC20
          limit: 2
          sorter: [
            { sort_type: DESC, sort_value: BLOCK_NUMBER },
            { sort_type: DESC, sort_value: ID }
          ]
        }
     ) {
        entries {
          transaction_hash
          block_number
        }

        metadata {
          total_count
          before
          after
        }
      }
    }
    """
  end
end
