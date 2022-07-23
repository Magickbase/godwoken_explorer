defmodule GodwokenExplorerWeb.API.WithdrawalRequestControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    udt = insert(:ckb_udt)
    insert(:ckb_account)
    %{hash: hash, number: number} = insert(:block)
    %{script_hash: script_hash, eth_address: eth_address} = insert(:user)

    withdrawal =
      insert(:withdrawal_request,
        account_script_hash: script_hash,
        block_hash: hash,
        block_number: number
      )

    %{withdrawal: withdrawal, eth_address: eth_address, udt: udt}
  end

  describe "index" do
    test "lists eth address withdrawal", %{
      conn: conn,
      withdrawal: withdrawal,
      eth_address: eth_address,
      udt: udt
    } do
      conn =
        get(
          conn,
          Routes.withdrawal_request_path(conn, :index, eth_address: to_string(eth_address))
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
                       "udt_id" => 1,
                       "value" => "0"
                     },
                     "id" => "#{withdrawal.id}",
                     "relationships" => %{"udt" => %{"data" => %{"id" => "1", "type" => "udt"}}},
                     "type" => "withdrawal_request"
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
