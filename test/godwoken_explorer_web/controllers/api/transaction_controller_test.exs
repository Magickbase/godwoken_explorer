defmodule GodwokenExplorerWeb.API.TransactionControllerTest do
  use GodwokenExplorer, :schema
  use GodwokenExplorerWeb.ConnCase

  alias Decimal, as: D

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

    {:ok, block} =
      Block.create_block(%{
        hash: "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
        parent_hash: "0xa04ecc2bb1bc634848535b60b3223c1cd5278aa93abb2c138687da8ffa9ffd48",
        number: 14,
        timestamp: ~U[2021-10-31 05:39:38.000000Z],
        status: :finalized,
        aggregator_id: 0,
        transaction_count: 1
      })

    Repo.insert(%Account{
      id: 0,
      nonce: 0,
      script_hash: "0x5c84fc6078725df72052cc858dffc6f352a069706c9023a82eeff3b2a1a9ccd1",
      short_address: "0x5c84fc6078725df72052cc858dffc6f352a06970",
      type: :meta_contract
    })

    {:ok, creator_transaction} =
      Transaction.create_transaction(%{
        args:
          "0x00000000790000000c0000006500000059000000100000003000000031000000636b89329db092883883ab5256e435ccabeee07b52091a78be22179636affce8012400000040d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b010000000100000001000000000000000000000000000000",
        block_hash: block.hash,
        block_number: block.number,
        from_account_id: 468,
        hash: "0xfedbbb474af0e0c93026946a6cfb44cd221ac97d7159600db51a59367f2a8ee0",
        nonce: 0,
        to_account_id: 0,
        type: :polyjuice_creator,
        code_hash: "0x636b89329db092883883ab5256e435ccabeee07b52091a78be22179636affce8",
        fee_amount: D.new(1),
        fee_udt_id: 1,
        script_args: "40d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b01000000",
        hash_type: "type"
      })

    creator_transaction
    |> Ecto.Changeset.change(%{
      inserted_at: NaiveDateTime.truncate(~U[2021-10-31 05:39:38.000000Z], :second)
    })
    |> Repo.update()

    Account.create_or_update_account!(%{
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

    Account.create_or_update_account!(%{
      id: 12119,
      nonce: 0,
      script: %{
        "args" =>
          "0x40d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b0300000025919d91b3d11e8d802ceec30b63298e1a603285",
        "code_hash" => "0x636b89329db092883883ab5256e435ccabeee07b52091a78be22179636affce8",
        "hash_type" => "type",
        "name" => "validator"
      },
      eth_address: "0x25919d91b3d11e8d802ceec30b63298e1a603285",
      script_hash: "0xb02c930c2825a960a50ba4ab005e8264498b64a0f1a07ccb17ff4852987b5e7b",
      short_address: "0xb02c930c2825a960a50ba4ab005e8264498b64a0",
      type: :polyjuice_contract
    })

    UDT.find_or_create_by(%{
      id: 12119,
      name: "Yokai",
      decimal: 18,
      supply: D.new(1_000_000_000),
      symbol: "YOK",
      type: :native
    })

    Repo.insert(%SmartContract{
      account_id: 12119,
      abi: Jason.decode!(File.read!(Path.join(["test/support", "erc20_abi.json"]))),
      contract_source_code: "abc",
      name: "Yokai"
    })

    Repo.insert(%ContractMethod{
      abi: %{
        "constant" => false,
        "inputs" => [
          %{"name" => "_to", "type" => "address"},
          %{"name" => "_value", "type" => "uint256"}
        ],
        "name" => "transfer",
        "outputs" => [%{"name" => "", "type" => "bool"}],
        "payable" => false,
        "stateMutability" => "nonpayable",
        "type" => "function"
      },
      identifier: <<169, 5, 156, 187>>,
      type: "function"
    })

    {:ok, tx} =Repo.insert(%Transaction{
      block_hash: block.hash,
      block_number: block.number,
      from_account_id: 468,
      hash: "0x5d71c8a372aab6a326c31e02a50829b65be278913cb0d0eb990e5714a1b38ff5",
      nonce: 78,
      args:
        "0xffffff504f4c59000000000100000000010000000000000000000000000000000000000000000000000000000000000044000000a9059cbb000000000000000000000000fa2ae9de22bbca35fc44f20efe7a3d2789556d4c000000000000000000000000000000000000000000000000158059d80c7ac463",
      to_account_id: 12119,
      type: :polyjuice
    })

    Repo.insert(%Polyjuice{
      tx_hash: "0x5d71c8a372aab6a326c31e02a50829b65be278913cb0d0eb990e5714a1b38ff5",
      is_create: false,
      gas_limit: 16_777_216,
      gas_price: D.new(1),
      gas_used: 44483,
      value: D.new(0),
      input_size: 68,
      input:
        "0xa9059cbb000000000000000000000000fa2ae9de22bbca35fc44f20efe7a3d2789556d4c000000000000000000000000000000000000000000000000158059d80c7ac463",
      status: :succeed
    })

    %{tx: tx}
  end

  describe "index" do
    test "lists user txs of contract", %{conn: conn, tx: tx} do
      conn =
        get(
          conn,
          Routes.transaction_path(conn, :index,
            eth_address: "0x085a61d7164735FC5378E590b5ED1448561e1a48",
            contract_address: "0xb02c930c2825a960a50ba4ab005e8264498b64a0"
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 1,
                 "txs" => [
                   %{
                     "block_number" => 14,
                     "l1_block_number" => nil,
                     "block_hash" =>
                       "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
                     "fee" => "0.00044483",
                     "from" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                     "to" => "0xb02c930c2825a960a50ba4ab005e8264498b64a0",
                     "to_alias" => "Yokai",
                     "gas_limit" => 16_777_216,
                     "gas_price" => D.new(1) |> D.div(Integer.pow(10, 8)) |> D.to_string(:normal),
                     "gas_used" => 44483,
                     "hash" =>
                       "0x5d71c8a372aab6a326c31e02a50829b65be278913cb0d0eb990e5714a1b38ff5",
                     "nonce" => 78,
                     "timestamp" => tx.inserted_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "udt_id" => 12119,
                     "udt_symbol" => "YOK",
                     "udt_icon" => nil,
                     "type" => "polyjuice",
                     "value" => "0",
                     "method" => "Transfer",
                     "status" => "finalized",
                     "polyjuice_status" => "succeed"
                   }
                 ]
               }
    end

    test "lists txs of block", %{conn: conn, tx: tx} do
      conn =
        get(
          conn,
          Routes.transaction_path(conn, :index,
            block_hash: "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518"
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 2,
                 "txs" => [
                   %{
                     "block_number" => 14,
                     "l1_block_number" => nil,
                     "block_hash" =>
                       "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
                     "fee" => "0.00044483",
                     "from" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                     "to" => "0xb02c930c2825a960a50ba4ab005e8264498b64a0",
                     "to_alias" => "Yokai",
                     "gas_limit" => 16_777_216,
                     "gas_price" => D.new(1) |> D.div(Integer.pow(10, 8)) |> D.to_string(:normal),
                     "gas_used" => 44483,
                     "hash" =>
                       "0x5d71c8a372aab6a326c31e02a50829b65be278913cb0d0eb990e5714a1b38ff5",
                     "nonce" => 78,
                     "timestamp" => tx.inserted_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "udt_id" => 12119,
                     "udt_symbol" => "YOK",
                     "udt_icon" => nil,
                     "type" => "polyjuice",
                     "value" => "0",
                     "method" => "Transfer",
                     "status" => "finalized",
                     "polyjuice_status" => "succeed"
                   },
                   %{
                     "block_number" => 14,
                     "l1_block_number" => nil,
                     "block_hash" =>
                       "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
                     "fee" => "",
                     "from" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                     "to" => "0x5c84fc6078725df72052cc858dffc6f352a06970",
                     "to_alias" => "0x5c84fc6078725df72052cc858dffc6f352a06970",
                     "gas_limit" => nil,
                     "gas_price" => "",
                     "gas_used" => nil,
                     "hash" =>
                       "0xfedbbb474af0e0c93026946a6cfb44cd221ac97d7159600db51a59367f2a8ee0",
                     "nonce" => 0,
                     "timestamp" => 1_635_658_778,
                     "udt_id" => nil,
                     "udt_symbol" => nil,
                     "udt_icon" => nil,
                     "type" => "polyjuice_creator",
                     "value" => "",
                     "method" => nil,
                     "status" => "finalized",
                     "polyjuice_status" => nil
                   }
                 ]
               }
    end

    test "lists all txs", %{conn: conn, tx: tx} do
      conn =
        get(
          conn,
          Routes.transaction_path(conn, :index)
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 2,
                 "txs" => [
                   %{
                     "block_number" => 14,
                     "l1_block_number" => nil,
                     "block_hash" =>
                       "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
                     "fee" => "0.00044483",
                     "from" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                     "to" => "0xb02c930c2825a960a50ba4ab005e8264498b64a0",
                     "to_alias" => "Yokai",
                     "gas_limit" => 16_777_216,
                     "gas_price" => D.new(1) |> D.div(Integer.pow(10, 8)) |> D.to_string(:normal),
                     "gas_used" => 44483,
                     "hash" =>
                       "0x5d71c8a372aab6a326c31e02a50829b65be278913cb0d0eb990e5714a1b38ff5",
                     "nonce" => 78,
                     "timestamp" => tx.inserted_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "udt_id" => 12119,
                     "udt_symbol" => "YOK",
                     "udt_icon" => nil,
                     "type" => "polyjuice",
                     "value" => "0",
                     "method" => "Transfer",
                     "status" => "finalized",
                     "polyjuice_status" => "succeed"
                   },
                   %{
                     "block_number" => 14,
                     "l1_block_number" => nil,
                     "block_hash" =>
                       "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
                     "fee" => "",
                     "from" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                     "to" => "0x5c84fc6078725df72052cc858dffc6f352a06970",
                     "to_alias" => "0x5c84fc6078725df72052cc858dffc6f352a06970",
                     "gas_limit" => nil,
                     "gas_price" => "",
                     "gas_used" => nil,
                     "hash" =>
                       "0xfedbbb474af0e0c93026946a6cfb44cd221ac97d7159600db51a59367f2a8ee0",
                     "nonce" => 0,
                     "timestamp" => 1_635_658_778,
                     "udt_id" => nil,
                     "udt_symbol" => nil,
                     "udt_icon" => nil,
                     "type" => "polyjuice_creator",
                     "value" => "",
                     "method" => nil,
                     "status" => "finalized",
                     "polyjuice_status" => nil
                   }
                 ]
               }
    end
  end

  describe "GET #show" do
    test "show polyjuice tx by hash", %{conn: conn, tx: tx} do
      conn =
        get(
          conn,
          Routes.transaction_path(
            conn,
            :show,
            "0x5d71c8a372aab6a326c31e02a50829b65be278913cb0d0eb990e5714a1b38ff5"
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "block_number" => 14,
                 "l1_block_number" => nil,
                 "block_hash" =>
                   "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
                 "fee" => "0.00044483",
                 "from" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                 "to" => "0xb02c930c2825a960a50ba4ab005e8264498b64a0",
                 "to_alias" => "Yokai",
                 "gas_limit" => 16_777_216,
                 "gas_price" => D.new(1) |> D.div(Integer.pow(10, 8)) |> D.to_string(:normal),
                 "gas_used" => 44483,
                 "hash" => "0x5d71c8a372aab6a326c31e02a50829b65be278913cb0d0eb990e5714a1b38ff5",
                 "nonce" => 78,
                 "timestamp" => tx.inserted_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                 "udt_id" => 12119,
                 "udt_symbol" => "YOK",
                 "udt_icon" => nil,
                 "type" => "polyjuice",
                 "value" => "0",
                 "status" => "finalized",
                 "polyjuice_status" => "succeed",
                 "contract_abi" =>
                   Jason.decode!(File.read!(Path.join(["test/support", "erc20_abi.json"]))),
                 "input" =>
                   "0xa9059cbb000000000000000000000000fa2ae9de22bbca35fc44f20efe7a3d2789556d4c000000000000000000000000000000000000000000000000158059d80c7ac463"
               }
    end

    test "show polyjuice creator tx by hash", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.transaction_path(
            conn,
            :show,
            "0xfedbbb474af0e0c93026946a6cfb44cd221ac97d7159600db51a59367f2a8ee0"
          )
        )

      assert json_response(conn, 200) ==
               %{
                 "block_number" => 14,
                 "l1_block_number" => nil,
                 "block_hash" =>
                   "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
                 "fee" => "",
                 "from" => "0x085a61d7164735fc5378e590b5ed1448561e1a48",
                 "to" => "0x5c84fc6078725df72052cc858dffc6f352a06970",
                 "to_alias" => "0x5c84fc6078725df72052cc858dffc6f352a06970",
                 "gas_limit" => nil,
                 "gas_price" => "",
                 "gas_used" => nil,
                 "hash" => "0xfedbbb474af0e0c93026946a6cfb44cd221ac97d7159600db51a59367f2a8ee0",
                 "nonce" => 0,
                 "timestamp" => 1_635_658_778,
                 "udt_id" => nil,
                 "udt_symbol" => nil,
                 "udt_icon" => nil,
                 "type" => "polyjuice_creator",
                 "value" => "",
                 "status" => "finalized",
                 "polyjuice_status" => nil,
                 "code_hash" =>
                   "0x636b89329db092883883ab5256e435ccabeee07b52091a78be22179636affce8",
                 "fee_amount" => "1",
                 "fee_udt" => "CKB",
                 "hash_type" => "type",
                 "script_args" =>
                   "40d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b01000000",
                 "input" => nil
               }
    end
  end
end
