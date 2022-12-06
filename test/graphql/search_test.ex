defmodule GodwokenExplorer.Graphql.SearchTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory, only: [insert: 2]

  setup do
    for _ <- 1..10 do
      insert(:native_udt, eth_type: :erc721)
      insert(:native_udt, eth_type: :erc1155)
    end

    []
  end

  test "graphql: search_udt ", %{conn: conn} do
    fuzzy_name = "%UD%"

    query = """
    query {
      search_udt(input: { fuzzy_name: "#{fuzzy_name}", limit: 1 }) {
        entries {
          id
          icon
          name
          symbol
          type
          eth_type
          contract_address_hash
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
                 "search_udt" => %{
                   "entries" => [%{"name" => "UDT" <> _}],
                   "metadata" => %{"total_count" => 20}
                 }
               }
             },
             json_response(conn, 200)
           )
  end
end
