defmodule GodwokenExplorerWeb.API.DepositWithdrawalControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory
  import GodwokenRPC.Util, only: [balance_to_view: 2]

  setup do
    udt = insert(:ckb_udt)
    insert(:ckb_account)
    user = insert(:user)
    block = insert(:block)

    deposit = insert(:deposit_history, script_hash: user.script_hash)

    withdrawal =
      insert(:withdrawal_history,
        l2_script_hash: user.script_hash,
        block_number: block.number,
        block_hash: block.hash
      )

    %{deposit: deposit, user: user, udt: udt, withdrawal: withdrawal, block: block}
  end

  describe "index" do
    test "when eth address account not exist", %{
      conn: conn
    } do
      conn =
        get(
          conn,
          Routes.deposit_withdrawal_path(conn, :index,
            eth_address: "0x5d6718b0a5192a30618801788b7d75c72d307f03"
          )
        )

      assert json_response(conn, 200) == %{"data" => [], "page" => 1, "total_count" => 0}
    end

    test "lists by block_number", %{
      conn: conn,
      user: user,
      udt: udt,
      withdrawal: withdrawal,
      block: block
    } do
      conn =
        get(
          conn,
          Routes.deposit_withdrawal_path(conn, :index, block_number: block.number)
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "block_hash" => to_string(block.hash),
                     "block_number" => block.number,
                     "ckb_lock_hash" => nil,
                     "eth_address" => to_string(user.eth_address),
                     "layer1_block_number" => withdrawal.layer1_block_number,
                     "layer1_output_index" => withdrawal.layer1_output_index,
                     "layer1_tx_hash" => to_string(withdrawal.layer1_tx_hash),
                     "owner_lock_hash" => to_string(withdrawal.owner_lock_hash),
                     "script_hash" => to_string(withdrawal.l2_script_hash),
                     "sudt_script_hash" => to_string(udt.script_hash),
                     "timestamp" => withdrawal.timestamp |> DateTime.to_iso8601(),
                     "type" => "withdrawal",
                     "udt_icon" => udt.icon,
                     "udt_id" => udt.id,
                     "udt_name" => udt.name,
                     "udt_symbol" => udt.symbol,
                     "value" => withdrawal.amount |> balance_to_view(udt.decimal),
                     "state" => "pending",
                     "capacity" => withdrawal.capacity |> Decimal.to_string(),
                     "udt_decimal" => udt.decimal
                   }
                 ],
                 "page" => 1,
                 "total_count" => 1
               }
    end

    test "lists by udt_id", %{
      conn: conn,
      deposit: deposit,
      user: user,
      udt: udt,
      withdrawal: withdrawal,
      block: block
    } do
      conn =
        get(
          conn,
          Routes.deposit_withdrawal_path(conn, :index, udt_id: udt.id)
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "block_hash" => to_string(block.hash),
                     "block_number" => block.number,
                     "ckb_lock_hash" => nil,
                     "eth_address" => to_string(user.eth_address),
                     "layer1_block_number" => withdrawal.layer1_block_number,
                     "layer1_output_index" => withdrawal.layer1_output_index,
                     "layer1_tx_hash" => to_string(withdrawal.layer1_tx_hash),
                     "owner_lock_hash" => to_string(withdrawal.owner_lock_hash),
                     "script_hash" => to_string(withdrawal.l2_script_hash),
                     "sudt_script_hash" => to_string(udt.script_hash),
                     "timestamp" => withdrawal.timestamp |> DateTime.to_iso8601(),
                     "type" => "withdrawal",
                     "udt_icon" => udt.icon,
                     "udt_id" => udt.id,
                     "udt_name" => udt.name,
                     "udt_symbol" => udt.symbol,
                     "value" => withdrawal.amount |> balance_to_view(udt.decimal),
                     "state" => "pending",
                     "capacity" => withdrawal.capacity |> Decimal.to_string(),
                     "udt_decimal" => udt.decimal
                   },
                   %{
                     "block_hash" => nil,
                     "block_number" => nil,
                     "ckb_lock_hash" => to_string(deposit.ckb_lock_hash),
                     "eth_address" => to_string(user.eth_address),
                     "layer1_block_number" => deposit.layer1_block_number,
                     "layer1_output_index" => deposit.layer1_output_index,
                     "layer1_tx_hash" => to_string(deposit.layer1_tx_hash),
                     "owner_lock_hash" => nil,
                     "script_hash" => to_string(deposit.script_hash),
                     "sudt_script_hash" => nil,
                     "timestamp" => deposit.timestamp |> DateTime.to_iso8601(),
                     "type" => "deposit",
                     "udt_icon" => udt.icon,
                     "udt_id" => udt.id,
                     "udt_name" => udt.name,
                     "udt_symbol" => udt.symbol,
                     "value" => deposit.amount |> balance_to_view(udt.decimal),
                     "state" => "succeed",
                     "capacity" => deposit.capacity |> Decimal.to_string(),
                     "udt_decimal" => udt.decimal
                   }
                 ],
                 "page" => "1",
                 "total_count" => "2"
               }
    end
  end
end
