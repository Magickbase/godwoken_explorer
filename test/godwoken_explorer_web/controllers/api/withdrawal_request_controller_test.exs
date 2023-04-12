defmodule GodwokenExplorerWeb.API.WithdrawalRequestControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    udt = insert(:ckb_udt)
    insert(:ckb_account)
    ckb_native = insert(:ckb_native_udt)
    ckb_contract = insert(:ckb_contract_account, eth_address: ckb_native.contract_address_hash)
    %{hash: hash, number: number} = insert(:block)
    %{script_hash: script_hash, eth_address: eth_address} = insert(:user)

    withdrawal =
      insert(:withdrawal_request,
        account_script_hash: script_hash,
        block_hash: hash,
        block_number: number
      )

    %{withdrawal: withdrawal, eth_address: eth_address, udt: udt, ckb_contract: ckb_contract}
  end

  describe "index" do
    test "lists eth address withdrawal", %{
      conn: conn,
      withdrawal: withdrawal,
      eth_address: eth_address,
      udt: udt,
      ckb_contract: ckb_contract
    } do
      conn =
        get(
          conn,
          ~p"/api/withdrawal_requests?eth_address=#{to_string(eth_address)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "account_script_hash" => to_string(withdrawal.account_script_hash),
                       "block_hash" => to_string(withdrawal.block_hash),
                       "block_number" => withdrawal.block_number,
                       "capacity" => "383220966182",
                       "nonce" => 0,
                       "owner_lock_hash" => to_string(withdrawal.owner_lock_hash),
                       "sudt_script_hash" =>
                         "0x0000000000000000000000000000000000000000000000000000000000000000",
                       "value" => "0",
                       "udt_id" => udt.id,
                       "udt" => %{
                         "eth_address" => ckb_contract.eth_address |> to_string(),
                         "name" => udt.name,
                         "symbol" => udt.symbol
                       }
                     },
                     "id" => "#{withdrawal.id}",
                     "relationships" => %{},
                     "type" => "withdrawal_request"
                   }
                 ],
                 "included" => [],
                 "meta" => %{"current_page" => 1, "total_page" => 1}
               }
    end

    test "no params passed", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/withdrawal_requests"
        )

      assert json_response(conn, 400) == %{
               "errors" => %{"detail" => "", "status" => "400", "title" => "bad request"}
             }
    end
  end
end
