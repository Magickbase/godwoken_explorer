defmodule GodwokenExplorerWeb.API.DepositHistoryControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory
  import GodwokenRPC.Util, only: [balance_to_view: 2]

  setup do
    udt = insert(:ckb_udt)
    insert(:ckb_account)
    ckb_native = insert(:ckb_native_udt)
    ckb_contract = insert(:ckb_contract_account, eth_address: ckb_native.contract_address_hash)
    user = insert(:user)

    deposit = insert(:deposit_history, script_hash: user.script_hash)
    %{deposit: deposit, user: user, udt: udt, ckb_contract: ckb_contract}
  end

  describe "index" do
    test "lists eth address deposit", %{
      conn: conn,
      deposit: deposit,
      user: user,
      udt: udt,
      ckb_contract: ckb_contract
    } do
      conn =
        get(
          conn,
          ~p"/api/deposit_histories?eth_address=#{to_string(user.eth_address)}"
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
                       "value" => deposit.amount |> balance_to_view(udt.decimal),
                       "capacity" => deposit.capacity |> to_string(),
                       "udt_id" => udt.id,
                       "udt" => %{
                         "eth_address" => ckb_contract.eth_address |> to_string(),
                         "name" => udt.name,
                         "symbol" => udt.symbol
                       }
                     },
                     "id" => "#{deposit.id}",
                     "relationships" => %{},
                     "type" => "deposit_history"
                   }
                 ],
                 "included" => [],
                 "meta" => %{"current_page" => 1, "total_page" => 1}
               }
    end
  end
end
