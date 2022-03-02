defmodule GodwokenExplorerWeb.API.WithdrawalRequestControllerTest do
  use GodwokenExplorerWeb.ConnCase
  use GodwokenExplorer, :schema

  setup do
    UDT.find_or_create_by(%{
      id: 1,
      name: "CKB",
      decimal: 8,
      script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      type: :bridge
    })
    Account.create_or_update_account!(%{
      id: 1,
      type: :udt,
      short_address: "0x9e9c54293c3211259de788e97a31b5b3a66cd535",
      script_hash: "0x9e9c54293c3211259de788e97a31b5b3a66cd53564f8d39dfabdc8e96cdf5ea4"
    })


    Repo.insert(%Account{
      id: 468,
      nonce: 90,
      script: %{
        "args" =>
          "0x40d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b085a61d7164735fc5378e590b5ed1448561e1a48",
        "code_hash" => "0x1563080d175bf8ddd44a48e850cecf0c0b4575835756eb5ffd53ad830931b9f9",
        "hash_type" => "type"
      },
      script_hash: "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
      short_address: "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c",
      eth_address: "0x085a61d7164735fc5378e590b5ed1448561e1a48",
      type: :eth_user
    })

    {:ok, withdrawal} =
      WithdrawalRequest.create_withdrawal_request(%{
        account_script_hash: "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
        amount: D.new(0),
        block_hash: "0x07aafde68ea70169bb54cf76b44496d8f5deba5ac89cb1ddc20d10646ddfc09f",
        block_number: 68738,
        capacity: D.new(383_220_966_182),
        fee_amount: D.new(0),
        fee_udt_id: 1,
        nonce: 59,
        owner_lock_hash: "0x66db0f8f6b0ac8b4e92fdfcef8d04a3251a118ccae0ff436957e2c646f083ebd",
        payment_lock_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        sell_amount: D.new(0),
        sell_capacity: D.new(0),
        sudt_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        udt_id: 1
      })

    %{withdrawal: withdrawal}
  end

  describe "index" do
    test "lists eth address withdrawal", %{conn: conn, withdrawal: withdrawal} do
      conn =
        get(
          conn,
          Routes.withdrawal_request_path(conn, :index,
            eth_address: "0x085a61d7164735FC5378E590b5ED1448561e1a48"
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "account_script_hash" =>
                         "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
                       "block_hash" =>
                         "0x07aafde68ea70169bb54cf76b44496d8f5deba5ac89cb1ddc20d10646ddfc09f",
                       "block_number" => 68738,
                       "ckb" => "3832.20966182",
                       "nonce" => 59,
                       "owner_lock_hash" =>
                         "0x66db0f8f6b0ac8b4e92fdfcef8d04a3251a118ccae0ff436957e2c646f083ebd",
                       "payment_lock_hash" =>
                         "0x0000000000000000000000000000000000000000000000000000000000000000",
                       "sell_ckb" => "0",
                       "sell_value" => "0",
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
                       "decimal" => 8,
                       "description" => nil,
                       "holder_count" => 0,
                       "icon" => nil,
                       "id" => 1,
                       "name" => "CKB",
                       "official_site" => nil,
                       "script_hash" =>
                         "0x0000000000000000000000000000000000000000000000000000000000000000",
                       "short_address" => "0x9e9c54293c3211259de788e97a31b5b3a66cd535",
                       "supply" => "",
                       "symbol" => nil,
                       "transfer_count" => 0,
                       "type" => "bridge",
                       "type_script" => nil,
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
