defmodule GodwokenExplorerWeb.API.HomeControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory
  import GodwokenRPC.Util, only: [utc_to_unix: 1]
  import Mock

  alias GodwokenExplorer.Chain.Cache.TransactionCount

  setup do
    user = insert(:user)
    contract = insert(:polyjuice_contract_account)
    block = insert(:block, transaction_count: 1)

    tx =
      insert(:transaction, block: block, from_account: user, to_account: contract)
      |> with_polyjuice()

    %{block: block, tx: tx, user: user, contract: contract}
  end

  describe "index" do
    test "return home data", %{conn: conn, block: block, tx: tx, user: user, contract: contract} do
      with_mock TransactionCount,
        estimated_count: fn ->
          1
        end do
        conn =
          get(
            conn,
            ~p"/api/home"
          )

        assert json_response(conn, 200) ==
                 %{
                   "block_list" => [
                     %{
                       "hash" => to_string(block.hash),
                       "number" => block.number,
                       "timestamp" => utc_to_unix(block.timestamp),
                       "tx_count" => block.transaction_count
                     }
                   ],
                   "statistic" => %{
                     "account_count" => "0",
                     "average_block_time" => 0.0,
                     "block_count" => Integer.to_string(block.number + 1),
                     "tps" => "0.0",
                     "tx_count" => "1"
                   },
                   "tx_list" => [
                     %{
                       "block_number" => block.number,
                       "from" => to_string(user.eth_address),
                       "hash" => to_string(tx.eth_hash),
                       "index" => tx.index,
                       "timestamp" => utc_to_unix(block.timestamp),
                       "to" => to_string(contract.eth_address),
                       "to_alias" => to_string(contract.eth_address),
                       "type" => "polyjuice"
                     }
                   ]
                 }
      end
    end
  end
end
