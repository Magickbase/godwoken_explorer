defmodule GodwokenExplorerWeb.API.BlockControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenRPC.Util, only: [utc_to_unix: 1]
  import GodwokenExplorer.Factory

  setup do
    insert(:meta_contract)
    block = insert(:block)

    %{block: block}
  end

  describe "index" do
    test "return all block", %{conn: conn, block: block} do
      conn =
        get(
          conn,
          Routes.block_path(
            conn,
            :index
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "finalize_state" => to_string(block.status),
                       "gas_limit" => block.gas_limit |> Decimal.to_string(),
                       "gas_used" => block.gas_used |> Decimal.to_string(),
                       "hash" => to_string(block.hash),
                       "miner_hash" => to_string(block.producer_address),
                       "number" => block.number,
                       "timestamp" => utc_to_unix(block.timestamp),
                       "tx_count" => 0
                     },
                     "id" => block.number,
                     "relationships" => %{},
                     "type" => "block"
                   }
                 ],
                 "included" => [],
                 "meta" => %{"current_page" => 1, "total_page" => 1}
               }
    end
  end

  describe "show" do
    test "when block exist", %{conn: conn, block: block} do
      conn =
        get(
          conn,
          Routes.block_path(
            conn,
            :show,
            to_string(block.hash)
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "finalize_state" => to_string(block.status),
                 "gas_limit" => block.gas_limit |> Decimal.to_string(),
                 "gas_used" => block.gas_used |> Decimal.to_string(),
                 "hash" => to_string(block.hash),
                 "miner_hash" => to_string(block.producer_address),
                 "number" => block.number,
                 "timestamp" => utc_to_unix(block.timestamp),
                 "tx_count" => 0,
                 "l1_block" => nil,
                 "l1_tx_hash" => nil,
                 "logs_bloom" => nil,
                 "parent_hash" => to_string(block.parent_hash),
                 "size" => block.size
               }
    end
  end
end
