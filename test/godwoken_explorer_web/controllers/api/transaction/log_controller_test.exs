defmodule GodwokenExplorerWeb.API.Transaction.LogControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    tx = insert(:transaction) |> with_polyjuice()
    log = insert(:log, transaction_hash: tx.eth_hash)
    %{log: log, tx: tx}
  end

  describe "index" do
    test "return account's logs", %{conn: conn, log: log, tx: tx} do
      transaction_hash = to_string(tx.eth_hash)

      conn =
        get(
          conn,
          ~p"/api/txs/#{transaction_hash}/logs"
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "abi" => nil,
                       "address_hash" => to_string(log.address_hash),
                       "block_number" => log.block_number,
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
                 "meta" => %{"current_page" => 1, "total_page" => 1}
               }
    end
  end
end
