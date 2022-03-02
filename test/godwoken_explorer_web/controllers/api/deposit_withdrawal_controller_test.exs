defmodule GodwokenExplorerWeb.API.DepositWithdrawalControllerTest do
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

    Block.create_block(%{
      hash: "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
      parent_hash: "0xa04ecc2bb1bc634848535b60b3223c1cd5278aa93abb2c138687da8ffa9ffd48",
      number: 68738,
      timestamp: ~U[2021-10-31 05:39:38.000000Z],
      status: :finalized,
      aggregator_id: 0,
      transaction_count: 1
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

    WithdrawalHistory.create_or_update_history!(%{
      l2_script_hash: "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
      amount: D.new(10_000_000_000),
      block_hash: "0x07aafde68ea70169bb54cf76b44496d8f5deba5ac89cb1ddc20d10646ddfc09f",
      block_number: 68738,
      owner_lock_hash: "0x66db0f8f6b0ac8b4e92fdfcef8d04a3251a118ccae0ff436957e2c646f083ebd",
      payment_lock_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      sell_amount: D.new(0),
      sell_capacity: D.new(0),
      udt_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      udt_id: 1,
      layer1_block_number: 5_744_914,
      layer1_output_index: 0,
      layer1_tx_hash: "0x41876f5c3ea0d96219c42ea5b4e6cedba61c59fa39bf163765a302f6e43c3847",
      timestamp: ~U[2021-12-03 22:39:39.585000Z],
      state: :pending
    })

    DepositHistory.create_or_update_history!(%{
      amount: D.new(40_000_000_000),
      ckb_lock_hash: "0xe6c7befcbf4697f1a7f8f04ffb8de71f5304826af7bfce3e4d396483e935820a",
      layer1_block_number: 5_744_914,
      layer1_output_index: 0,
      layer1_tx_hash: "0x41876f5c3ea0d96219c42ea5b4e6cedba61c59fa39bf163765a302f6e43c3847",
      script_hash: "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
      timestamp: ~U[2021-12-02 22:39:39.585000Z],
      udt_id: 1
    })

    :ok
  end

  describe "index" do
    test "when eth address account not exist", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.deposit_withdrawal_path(conn, :index,
            eth_address: "0x085a61d7164735FC5378E590b5ED1448561e1a4"
          )
        )

      assert json_response(conn, 404) ==
               %{"errors" => %{"detail" => "", "status" => "404", "title" => "not found"}}
    end

    test "lists by block_number", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.deposit_withdrawal_path(conn, :index, block_number: "68738")
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "block_hash" =>
                       "0x07aafde68ea70169bb54cf76b44496d8f5deba5ac89cb1ddc20d10646ddfc09f",
                     "block_number" => 68738,
                     "ckb_lock_hash" => nil,
                     "eth_address" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                     "layer1_block_number" => 5_744_914,
                     "layer1_output_index" => 0,
                     "layer1_tx_hash" =>
                       "0x41876f5c3ea0d96219c42ea5b4e6cedba61c59fa39bf163765a302f6e43c3847",
                     "owner_lock_hash" =>
                       "0x66db0f8f6b0ac8b4e92fdfcef8d04a3251a118ccae0ff436957e2c646f083ebd",
                     "payment_lock_hash" =>
                       "0x0000000000000000000000000000000000000000000000000000000000000000",
                     "script_hash" =>
                       "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
                     "sell_capacity" => "0",
                     "sell_value" => "0.0000000000000000000000000000",
                     "sudt_script_hash" =>
                       "0x0000000000000000000000000000000000000000000000000000000000000000",
                     "timestamp" => "2021-12-03T22:39:39.585000Z",
                     "type" => "withdrawal",
                     "udt_icon" => nil,
                     "udt_id" => 1,
                     "udt_name" => "CKB",
                     "udt_symbol" => nil,
                     "value" => "100.0000000000000000",
                     "state" => "pending"
                   }
                 ],
                 "page" => 1,
                 "total_count" => 1
               }
    end

    test "lists by udt_id", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.deposit_withdrawal_path(conn, :index, udt_id: "1")
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "block_hash" =>
                       "0x07aafde68ea70169bb54cf76b44496d8f5deba5ac89cb1ddc20d10646ddfc09f",
                     "block_number" => 68738,
                     "ckb_lock_hash" => nil,
                     "eth_address" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                     "layer1_block_number" => 5_744_914,
                     "layer1_output_index" => 0,
                     "layer1_tx_hash" =>
                       "0x41876f5c3ea0d96219c42ea5b4e6cedba61c59fa39bf163765a302f6e43c3847",
                     "owner_lock_hash" =>
                       "0x66db0f8f6b0ac8b4e92fdfcef8d04a3251a118ccae0ff436957e2c646f083ebd",
                     "payment_lock_hash" =>
                       "0x0000000000000000000000000000000000000000000000000000000000000000",
                     "script_hash" =>
                       "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
                     "sell_capacity" => "0",
                     "sell_value" => "0.0000000000000000000000000000",
                     "sudt_script_hash" =>
                       "0x0000000000000000000000000000000000000000000000000000000000000000",
                     "timestamp" => "2021-12-03T22:39:39.585000Z",
                     "type" => "withdrawal",
                     "udt_icon" => nil,
                     "udt_id" => 1,
                     "udt_name" => "CKB",
                     "udt_symbol" => nil,
                     "value" => "100.0000000000000000",
                     "state" => "pending"
                   },
                   %{
                     "block_hash" => nil,
                     "block_number" => nil,
                     "ckb_lock_hash" =>
                       "0xe6c7befcbf4697f1a7f8f04ffb8de71f5304826af7bfce3e4d396483e935820a",
                     "eth_address" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                     "layer1_block_number" => 5_744_914,
                     "layer1_output_index" => 0,
                     "layer1_tx_hash" =>
                       "0x41876f5c3ea0d96219c42ea5b4e6cedba61c59fa39bf163765a302f6e43c3847",
                     "owner_lock_hash" => nil,
                     "payment_lock_hash" => nil,
                     "script_hash" =>
                       "0xfa2ae9de22bbca35fc44f20efe7a3d2789556d4c50a7c2b4e460269f13b77c58",
                     "sell_capacity" => nil,
                     "sell_value" => nil,
                     "sudt_script_hash" => nil,
                     "timestamp" => "2021-12-02T22:39:39.585000Z",
                     "type" => "deposit",
                     "udt_icon" => nil,
                     "udt_id" => 1,
                     "udt_name" => "CKB",
                     "udt_symbol" => nil,
                     "value" => "400.0000000000000000",
                     "state" => "succeed"
                   }
                 ],
                 "page" => "1",
                 "total_count" => "2"
               }
    end
  end
end
