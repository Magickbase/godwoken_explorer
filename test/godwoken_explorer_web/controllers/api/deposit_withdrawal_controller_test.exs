defmodule GodwokenExplorerWeb.API.DepositWithdrawalControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory
  import GodwokenRPC.Util, only: [balance_to_view: 2]

  setup do
    native_udt = insert(:native_udt)
    udt = insert(:ckb_udt, bridge_account_id: native_udt.id)
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

    %{
      deposit: deposit,
      user: user,
      udt: udt,
      withdrawal: withdrawal,
      block: block,
      native_udt: native_udt
    }
  end

  describe "index" do
    test "when eth address account not exist", %{
      conn: conn
    } do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals?eth_address=0x5d6718b0a5192a30618801788b7d75c72d307f03"
        )

      assert json_response(conn, 200) == %{"data" => [], "page" => 1, "total_count" => 0}
    end

    test "export by eth address but not account exist", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals?eth_address=0x8bf38d4764929064f2d4d3a56520a76ab3df415b&export=true"
        )

      assert json_response(conn, 200) == %{"data" => [], "page" => 1, "total_count" => 0}
    end

    test "export by eth address", %{
      conn: conn,
      user: user,
      udt: udt,
      deposit: deposit,
      withdrawal: withdrawal,
      block: block
    } do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals?eth_address=#{to_string(user.eth_address)}&export=true"
        )

      parsed_withdrawal = %{
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

      parsed_deposit = %{
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

      assert response(conn, 200) ==
               "Type,Value,UDT Symbol,Capacity,UnixTimestamp,Address,Layer1 TxnHash,Block Number\r\n" <>
                 "withdrawal," <>
                 "#{parsed_withdrawal["value"]}," <>
                 "#{parsed_withdrawal["udt_symbol"]}," <>
                 "#{parsed_withdrawal["capacity"]}," <>
                 "#{parsed_withdrawal["timestamp"]}," <>
                 "#{parsed_withdrawal["eth_address"]}," <>
                 "#{parsed_withdrawal["layer1_tx_hash"]}," <>
                 "#{parsed_withdrawal["block_number"]}\r\n" <>
                 "deposit," <>
                 "#{parsed_deposit["value"]}," <>
                 "#{parsed_deposit["udt_symbol"]}," <>
                 "#{parsed_deposit["capacity"]}," <>
                 "#{parsed_deposit["timestamp"]}," <>
                 "#{parsed_deposit["eth_address"]}," <>
                 "#{parsed_deposit["layer1_tx_hash"]}," <>
                 "#{parsed_deposit["block_number"]}\r\n"
    end

    test "when passed eth_address params", %{
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
          ~p"/api/deposit_withdrawals?eth_address=#{to_string(user.eth_address)}"
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
          ~p"/api/deposit_withdrawals?block_number=#{block.number}"
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

    test "export by block_number", %{
      conn: conn,
      user: user,
      udt: udt,
      withdrawal: withdrawal,
      block: block
    } do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals?block_number=#{block.number}&export=true"
        )

      parsed_withdrawal = %{
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

      assert response(conn, 200) ==
               "Type,Value,UDT Symbol,Capacity,UnixTimestamp,Address,Layer1 TxnHash,Block Number\r\n" <>
                 "withdrawal," <>
                 "#{parsed_withdrawal["value"]}," <>
                 "#{parsed_withdrawal["udt_symbol"]}," <>
                 "#{parsed_withdrawal["capacity"]}," <>
                 "#{parsed_withdrawal["timestamp"]}," <>
                 "#{parsed_withdrawal["eth_address"]}," <>
                 "#{parsed_withdrawal["layer1_tx_hash"]}," <>
                 "#{parsed_withdrawal["block_number"]}\r\n"
    end

    test "when udt not exist", %{
      conn: conn
    } do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals?udt_id=13196"
        )

      assert json_response(conn, 404) == %{
               "errors" => %{
                 "status" => "404",
                 "title" => "not found",
                 "detail" => ""
               }
             }
    end

    test "udt is bridge", %{
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
          ~p"/api/deposit_withdrawals?udt_id=#{udt.id}"
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

    test "export by udt_id and passed udt contract address hash", %{
      conn: conn,
      user: user,
      udt: udt,
      native_udt: native_udt,
      deposit: deposit,
      withdrawal: withdrawal,
      block: block
    } do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals?udt_id=#{to_string(native_udt.contract_address_hash)}&export=true"
        )

      parsed_withdrawal = %{
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

      parsed_deposit = %{
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

      assert response(conn, 200) ==
               "Type,Value,UDT Symbol,Capacity,UnixTimestamp,Address,Layer1 TxnHash,Block Number\r\n" <>
                 "withdrawal," <>
                 "#{parsed_withdrawal["value"]}," <>
                 "#{parsed_withdrawal["udt_symbol"]}," <>
                 "#{parsed_withdrawal["capacity"]}," <>
                 "#{parsed_withdrawal["timestamp"]}," <>
                 "#{parsed_withdrawal["eth_address"]}," <>
                 "#{parsed_withdrawal["layer1_tx_hash"]}," <>
                 "#{parsed_withdrawal["block_number"]}\r\n" <>
                 "deposit," <>
                 "#{parsed_deposit["value"]}," <>
                 "#{parsed_deposit["udt_symbol"]}," <>
                 "#{parsed_deposit["capacity"]}," <>
                 "#{parsed_deposit["timestamp"]}," <>
                 "#{parsed_deposit["eth_address"]}," <>
                 "#{parsed_deposit["layer1_tx_hash"]}," <>
                 "#{parsed_deposit["block_number"]}\r\n"
    end

    test "export by udt_id", %{
      conn: conn,
      user: user,
      udt: udt,
      deposit: deposit,
      withdrawal: withdrawal,
      block: block
    } do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals?udt_id=#{udt.id}&export=true"
        )

      parsed_withdrawal = %{
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

      parsed_deposit = %{
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

      assert response(conn, 200) ==
               "Type,Value,UDT Symbol,Capacity,UnixTimestamp,Address,Layer1 TxnHash,Block Number\r\n" <>
                 "withdrawal," <>
                 "#{parsed_withdrawal["value"]}," <>
                 "#{parsed_withdrawal["udt_symbol"]}," <>
                 "#{parsed_withdrawal["capacity"]}," <>
                 "#{parsed_withdrawal["timestamp"]}," <>
                 "#{parsed_withdrawal["eth_address"]}," <>
                 "#{parsed_withdrawal["layer1_tx_hash"]}," <>
                 "#{parsed_withdrawal["block_number"]}\r\n" <>
                 "deposit," <>
                 "#{parsed_deposit["value"]}," <>
                 "#{parsed_deposit["udt_symbol"]}," <>
                 "#{parsed_deposit["capacity"]}," <>
                 "#{parsed_deposit["timestamp"]}," <>
                 "#{parsed_deposit["eth_address"]}," <>
                 "#{parsed_deposit["layer1_tx_hash"]}," <>
                 "#{parsed_deposit["block_number"]}\r\n"
    end

    test "udt is native and passed udt's contract address hash", %{
      conn: conn,
      deposit: deposit,
      user: user,
      udt: udt,
      withdrawal: withdrawal,
      block: block,
      native_udt: native_udt
    } do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals?udt_id=#{to_string(native_udt.contract_address_hash)}"
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

    test "udt is native", %{
      conn: conn,
      deposit: deposit,
      user: user,
      udt: udt,
      withdrawal: withdrawal,
      block: block,
      native_udt: native_udt
    } do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals?udt_id=#{native_udt.id}"
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

    test "when no params passed", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/deposit_withdrawals"
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
