defmodule GodwokenExplorerWeb.API.DepositHistoryControllerTest do
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

    deposit = DepositHistory.create_or_update_history!(%{
      amount: D.new(40_000_000_000),
      ckb_lock_hash: "0xe6c7befcbf4697f1a7f8f04ffb8de71f5304826af7bfce3e4d396483e935820a",
      layer1_block_number: 5_744_914,
      layer1_output_index: 0,
      layer1_tx_hash: "0x41876f5c3ea0d96219c42ea5b4e6cedba61c59fa39bf163765a302f6e43c3847",
      script_hash: "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
      timestamp: ~U[2021-12-02 22:39:39.585000Z],
      udt_id: 1
    })

    %{deposit: deposit}
  end

  describe "index" do
    test "lists eth address deposit", %{conn: conn, deposit: deposit} do
      conn =
        get(
          conn,
          Routes.deposit_history_path(conn, :index,
            eth_address: "0x085a61d7164735FC5378E590b5ED1448561e1a48"
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "ckb_lock_hash" =>
                         "0xe6c7befcbf4697f1a7f8f04ffb8de71f5304826af7bfce3e4d396483e935820a",
                       "layer1_block_number" => 5_744_914,
                       "layer1_output_index" => 0,
                       "layer1_tx_hash" =>
                         "0x41876f5c3ea0d96219c42ea5b4e6cedba61c59fa39bf163765a302f6e43c3847",
                       "timestamp" => "2021-12-02T22:39:39.585000Z",
                       "udt_id" => 1,
                       "value" => "400"
                     },
                     "id" => "#{deposit.id}",
                     "relationships" => %{"udt" => %{"data" => %{"id" => "1", "type" => "udt"}}},
                     "type" => "deposit_history"
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
