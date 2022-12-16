defmodule GodwokenExplorer.Graphql.AddressTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    address = insert!(:address)

    %{
      address: address
    }
  end

  test "graphql: show address", %{
    conn: conn,
    address: address
  } do
    query = """
    query {
      address(
        input: {
          address: "#{address.eth_address}"
        })
         {
          eth_address
          bit_alias
          token_transfer_count
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
                 "address" => %{
                   "eth_address" => "#{address.eth_address}",
                   "bit_alias" => address.bit_alias,
                   "token_transfer_count" => nil
                 }
               }
             }
  end
end
