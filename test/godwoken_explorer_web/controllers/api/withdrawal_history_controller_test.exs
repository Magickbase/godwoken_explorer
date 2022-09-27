defmodule GodwokenExplorerWeb.API.WithdrawalHistoryControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory
  import Mock

  alias Decimal, as: D

  setup do
    udt = insert(:ckb_udt)
    insert(:ckb_account)
    ckb_native = insert(:ckb_native_udt)
    ckb_contract = insert(:ckb_contract_account, eth_address: ckb_native.contract_address_hash)
    user = insert(:user)

    withdrawal = insert(:withdrawal_history, l2_script_hash: user.script_hash)

    available_withdrawal =
      insert(:withdrawal_history, l2_script_hash: user.script_hash, state: :available)

    %{
      withdrawal: withdrawal,
      user: user,
      udt: udt,
      ckb_contract: ckb_contract,
      available_withdrawal: available_withdrawal
    }
  end

  describe "index" do
    test "lists eth address withdrawal", %{
      conn: conn,
      withdrawal: withdrawal,
      available_withdrawal: available_withdrawal,
      user: user,
      udt: udt,
      ckb_contract: ckb_contract
    } do
      with_mock GodwokenRPC, fetch_live_cell: fn _, _ -> {:ok, true} end do
        conn =
          get(
            conn,
            Routes.withdrawal_history_path(conn, :index, eth_address: to_string(user.eth_address))
          )

        assert json_response(conn, 200) ==
                 %{
                   "data" => [
                     %{
                       "attributes" => %{
                         "l2_script_hash" => to_string(available_withdrawal.l2_script_hash),
                         "block_hash" => to_string(available_withdrawal.block_hash),
                         "block_number" => available_withdrawal.block_number,
                         "udt_script_hash" => available_withdrawal.udt_script_hash |> to_string(),
                         "owner_lock_hash" => available_withdrawal.owner_lock_hash |> to_string(),
                         "state" => "#{available_withdrawal.state}",
                         "layer1_block_number" => available_withdrawal.layer1_block_number,
                         "layer1_output_index" => available_withdrawal.layer1_output_index,
                         "layer1_tx_hash" => to_string(available_withdrawal.layer1_tx_hash),
                         "timestamp" => available_withdrawal.timestamp |> DateTime.to_iso8601(),
                         "amount" => available_withdrawal.amount |> D.to_string(),
                         "capacity" => available_withdrawal.capacity |> to_string(),
                         "udt_id" => udt.id,
                         "udt" => %{
                           "eth_address" => ckb_contract.eth_address |> to_string(),
                           "name" => udt.name,
                           "symbol" => udt.symbol
                         }
                       },
                       "id" => "#{available_withdrawal.id}",
                       "relationships" => %{},
                       "type" => "withdrawal_history"
                     },
                     %{
                       "attributes" => %{
                         "l2_script_hash" => to_string(withdrawal.l2_script_hash),
                         "block_hash" => to_string(withdrawal.block_hash),
                         "block_number" => withdrawal.block_number,
                         "udt_script_hash" => withdrawal.udt_script_hash |> to_string(),
                         "owner_lock_hash" => withdrawal.owner_lock_hash |> to_string(),
                         "state" => "#{withdrawal.state}",
                         "layer1_block_number" => withdrawal.layer1_block_number,
                         "layer1_output_index" => withdrawal.layer1_output_index,
                         "layer1_tx_hash" => to_string(withdrawal.layer1_tx_hash),
                         "timestamp" => withdrawal.timestamp |> DateTime.to_iso8601(),
                         "amount" => withdrawal.amount |> D.to_string(),
                         "capacity" => withdrawal.capacity |> to_string(),
                         "udt_id" => udt.id,
                         "udt" => %{
                           "eth_address" => ckb_contract.eth_address |> to_string(),
                           "name" => udt.name,
                           "symbol" => udt.symbol
                         }
                       },
                       "id" => "#{withdrawal.id}",
                       "relationships" => %{},
                       "type" => "withdrawal_history"
                     }
                   ],
                   "included" => [],
                   "meta" => %{"current_page" => 1, "total_page" => 1}
                 }
      end
    end

    test "lists eth address unlocked withdrawal", %{
      conn: conn,
      available_withdrawal: available_withdrawal,
      user: user,
      udt: udt,
      ckb_contract: ckb_contract
    } do
      with_mock GodwokenRPC, fetch_live_cell: fn _, _ -> {:ok, true} end do
        conn =
          get(
            conn,
            Routes.withdrawal_history_path(conn, :index,
              eth_address: to_string(user.eth_address),
              state: "available"
            )
          )

        assert json_response(conn, 200) ==
                 %{
                   "data" => [
                     %{
                       "attributes" => %{
                         "l2_script_hash" => to_string(available_withdrawal.l2_script_hash),
                         "block_hash" => to_string(available_withdrawal.block_hash),
                         "block_number" => available_withdrawal.block_number,
                         "udt_script_hash" => available_withdrawal.udt_script_hash |> to_string(),
                         "owner_lock_hash" => available_withdrawal.owner_lock_hash |> to_string(),
                         "state" => "#{available_withdrawal.state}",
                         "layer1_block_number" => available_withdrawal.layer1_block_number,
                         "layer1_output_index" => available_withdrawal.layer1_output_index,
                         "layer1_tx_hash" => to_string(available_withdrawal.layer1_tx_hash),
                         "timestamp" => available_withdrawal.timestamp |> DateTime.to_iso8601(),
                         "amount" => available_withdrawal.amount |> D.to_string(),
                         "capacity" => available_withdrawal.capacity |> to_string(),
                         "udt_id" => udt.id,
                         "udt" => %{
                           "eth_address" => ckb_contract.eth_address |> to_string(),
                           "name" => udt.name,
                           "symbol" => udt.symbol
                         }
                       },
                       "id" => "#{available_withdrawal.id}",
                       "relationships" => %{},
                       "type" => "withdrawal_history"
                     }
                   ],
                   "included" => [],
                   "meta" => %{"current_page" => 1, "total_page" => 1}
                 }
      end
    end
  end
end
