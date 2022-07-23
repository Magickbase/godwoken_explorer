defmodule GodwokenExplorerWeb.API.DepositHistoryControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory
  import GodwokenRPC.Util, only: [balance_to_view: 2]

  setup do
    udt = insert(:ckb_udt)
    insert(:ckb_account)
    user = insert(:user)

    deposit = insert(:deposit_history, script_hash: user.script_hash)
    %{deposit: deposit, user: user, udt: udt}
  end

  describe "index" do
    test "lists eth address deposit", %{conn: conn, deposit: deposit, user: user, udt: udt} do
      conn =
        get(
          conn,
          Routes.deposit_history_path(conn, :index, eth_address: to_string(user.eth_address))
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "ckb_lock_hash" => to_string(deposit.ckb_lock_hash),
                       "layer1_block_number" => deposit.layer1_block_number,
                       "layer1_output_index" => deposit.layer1_output_index,
                       "layer1_tx_hash" => to_string(deposit.layer1_tx_hash),
                       "timestamp" => deposit.timestamp |> DateTime.to_iso8601(),
                       "udt_id" => 1,
                       "value" => deposit.amount |> balance_to_view(udt.decimal),
                       "capacity" => deposit.capacity |> to_string()
                     },
                     "id" => "#{deposit.id}",
                     "relationships" => %{"udt" => %{"data" => %{"id" => "1", "type" => "udt"}}},
                     "type" => "deposit_history"
                   }
                 ],
                 "included" => [
                   %{
                     "attributes" => %{
                       "decimal" => udt.decimal,
                       "description" => nil,
                       "holder_count" => 0,
                       "icon" => nil,
                       "id" => udt.id,
                       "name" => udt.name,
                       "official_site" => nil,
                       "eth_address" => "",
                       "supply" => udt.supply |> Decimal.to_string(),
                       "symbol" => nil,
                       "transfer_count" => 0,
                       "type" => "bridge",
                       "value" => nil
                     },
                     "id" => "1",
                     "relationships" => %{},
                     "type" => "udt"
                   }
                 ],
                 "meta" => %{"current_page" => 1, "total_page" => 1}
               }
    end
  end
end
