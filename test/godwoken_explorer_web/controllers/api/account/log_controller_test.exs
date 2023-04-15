defmodule GodwokenExplorerWeb.API.Account.LogControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    tx = insert(:transaction) |> with_polyjuice()
    log = insert(:log, transaction_hash: tx.eth_hash)
    %{log: log, tx: tx}
  end

  describe "index" do
    test "return account's logs", %{conn: conn, log: log, tx: tx} do
      address = to_string(log.address_hash)

      conn =
        get(
          conn,
          ~p"/api/accounts/#{address}/logs"
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "abi" => nil,
                       "address_hash" => address,
                       "block_number" => tx.block_number,
                       "data" => to_string(log.data),
                       "first_topic" => nil,
                       "fourth_topic" => nil,
                       "second_topic" => nil,
                       "third_topic" => nil,
                       "transaction_hash" => to_string(tx.eth_hash)
                     },
                     "id" => log.index,
                     "relationships" => %{},
                     "type" => "log"
                   }
                 ],
                 "included" => [],
                 "meta" => %{}
               }
    end

    test "when address invalid return error", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/accounts/0x123456/logs"
        )

      assert json_response(conn, 400) == %{
               "errors" => %{
                 "status" => "400",
                 "title" => "bad request",
                 "detail" => ""
               }
             }
    end

    test "when no address params", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/accounts/123456/logs"
        )

      assert json_response(conn, 404) == %{
               "errors" => %{
                 "status" => "404",
                 "title" => "not found",
                 "detail" => ""
               }
             }
    end
  end
end
