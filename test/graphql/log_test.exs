defmodule GodwokenExplorer.Graphql.LogTest do
  use GodwokenExplorerWeb.ConnCase

  @logs """
  query {
    logs(input: {first_topic: "0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0",end_block_number: 346283, page: 1, page_size: 1}) {
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

  ## TODO: add factory data
  setup do
    :ok
  end

  test "query: logs", %{conn: conn} do
    # conn =
    post(conn, "/graphql", %{
      "query" => @logs,
      "variables" => %{}
    })

    # assert json_response(conn, 200) == %{
    #          "data" => _
    #        }

    assert true
  end
end
