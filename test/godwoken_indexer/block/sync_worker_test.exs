defmodule GodwokenIndexer.Block.SyncWorkerTest do
  use GodwokenExplorer.DataCase

  import Hammox
  import GodwokenExplorer.Factory

  alias GodwokenExplorer.{
    Account,
    Block,
    Chain,
    Repo,
    Transaction,
    Log,
    TokenTransfer,
    Polyjuice,
    PolyjuiceCreator,
    WithdrawalRequest
  }

  alias GodwokenExplorer.GW.{SudtPayFee, SudtTransfer}
  alias GodwokenExplorer.Account.CurrentBridgedUDTBalance
  alias GodwokenIndexer.Block.SyncWorker

  setup do
    insert(:block,
      hash: "0x841290cff9bada0105c45f1110ba692ee03980f765b19cf71ad1a875eabd6ad4",
      number: 0
    )

    insert(:ckb_udt)
    udt = insert(:ckb_account)
    register = insert(:block_producer)

    {:ok, user_address_hash} =
      Chain.string_to_address_hash("0xe2d73bf4e1306002811258417152a3eaa4cd4794")

    {:ok, contract_address_hash} =
      Chain.string_to_address_hash("0x83963a90b74e165df914b53ed9a5e8b29f5550bf")

    %{
      user_address_hash: user_address_hash,
      contract_address_hash: contract_address_hash,
      register_address_hash: register.eth_address,
      udt: udt
    }
  end

  setup :verify_on_exit!

  describe "import_range/2" do
    test "import a block succeed", %{
      user_address_hash: user_address_hash,
      contract_address_hash: contract_address_hash,
      register_address_hash: register_address_hash
    } do
      MockGodwokenRPC
      |> expect(
        :fetch_blocks_by_range,
        fn 1..1 ->
          {:ok,
           %GodwokenRPC.Blocks{
             blocks_params: [
               %{
                 gas_limit: 11_875_000,
                 gas_used: 11_875_000,
                 hash: "0x9dc70371157f6afcd36a76a00ec6cae7d64eae839af8d82af57230416d3e7a72",
                 logs_bloom:
                   "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                 number: 347_086,
                 parent_hash:
                   "0x841290cff9bada0105c45f1110ba692ee03980f765b19cf71ad1a875eabd6ad4",
                 producer_address: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040",
                 registry_id: 2,
                 size: 368,
                 status: :committed,
                 timestamp: ~U[2022-09-06 01:35:48.892000Z],
                 transaction_count: 1
               }
             ],
             transactions_params: [
               %{
                 account_ids: [60691, 17544],
                 args:
                   "0xffffff504f4c5900b832b5000000000000a007c2da5100000000000000000000000000000000000000000000000000000401000086df31ee000000000000000000000000e2d73bf4e1306002811258417152a3eaa4cd479400000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000005000000000000000000000000c527cba92f5e578081d6533357104b2c095bb4b900000000000000000000000032e1c049f0dc3ba54bf600f02f51e4dae42e2efd000000000000000000000000d349bc6f260ebfe62c22c51bf47e1e2a499fdee20000000000000000000000007d0ff693a18065f2f3b0739a7d6948abc20cedd2000000000000000000000000e54b4d8ee3ee1cb58de2563566d1aee23a2128c8",
                 block_hash: "0x9dc70371157f6afcd36a76a00ec6cae7d64eae839af8d82af57230416d3e7a72",
                 block_number: 1,
                 from_account_id: 60691,
                 gas_limit: 11_875_000,
                 gas_price: 90_000_000_000_000,
                 hash: "0x5776aac4db7532eda5af049b441f2770cd37d264034d3be4e8cca11c3b59836b",
                 index: 0,
                 input:
                   "0x86df31ee000000000000000000000000e2d73bf4e1306002811258417152a3eaa4cd479400000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000005000000000000000000000000c527cba92f5e578081d6533357104b2c095bb4b900000000000000000000000032e1c049f0dc3ba54bf600f02f51e4dae42e2efd000000000000000000000000d349bc6f260ebfe62c22c51bf47e1e2a499fdee20000000000000000000000007d0ff693a18065f2f3b0739a7d6948abc20cedd2000000000000000000000000e54b4d8ee3ee1cb58de2563566d1aee23a2128c8",
                 input_size: 260,
                 is_create: false,
                 native_transfer_address_hash: nil,
                 call_contract: nil,
                 call_data: nil,
                 call_gas_limit: nil,
                 verification_gas_limit: nil,
                 max_fee_per_gas: nil,
                 max_priority_fee_per_gas: nil,
                 paymaster_and_data: nil,
                 nonce: 0,
                 to_account_id: 17544,
                 type: :polyjuice,
                 value: 0
               }
             ],
             withdrawal_params: [],
             errors: []
           }}
        end
      )
      |> expect(:fetch_script_hashes, fn ids ->
        assert ids == [%{account_id: 60691}, %{account_id: 17544}]

        {:ok,
         %GodwokenRPC.Account.FetchedScriptHashes{
           errors: [],
           params_list: [
             %{
               id: 17544,
               script_hash: "0xc0ebbf6313bdc6c3f3831d25bf44c30b46627787251420e4cabcb92d10bdde18"
             },
             %{
               id: 60691,
               script_hash: "0x96b5a6edfb5a91efd18da50df5f243fe89598195a8a65ccc53edf4fd9849230a"
             }
           ]
         }}
      end)
      |> expect(:fetch_scripts, fn script_hashes ->
        assert script_hashes == [
                 %{
                   id: 17544,
                   script_hash:
                     "0xc0ebbf6313bdc6c3f3831d25bf44c30b46627787251420e4cabcb92d10bdde18"
                 },
                 %{
                   id: 60691,
                   script_hash:
                     "0x96b5a6edfb5a91efd18da50df5f243fe89598195a8a65ccc53edf4fd9849230a"
                 }
               ]

        {:ok,
         %GodwokenRPC.Account.FetchedScripts{
           errors: [],
           params_list: [
             %{
               id: 60691,
               script: %{
                 "args" =>
                   "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8e2d73bf4e1306002811258417152a3eaa4cd4794",
                 "code_hash" =>
                   "0x07521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec0",
                 "hash_type" => "type"
               },
               script_hash: "0x96b5a6edfb5a91efd18da50df5f243fe89598195a8a65ccc53edf4fd9849230a"
             },
             %{
               id: 17544,
               script: %{
                 "args" =>
                   "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd80400000083963a90b74e165df914b53ed9a5e8b29f5550bf",
                 "code_hash" =>
                   "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
                 "hash_type" => "type"
               },
               script_hash: "0xc0ebbf6313bdc6c3f3831d25bf44c30b46627787251420e4cabcb92d10bdde18"
             }
           ]
         }}
      end)
      |> expect(:fetch_gw_transaction_receipts, fn gw_hashes ->
        assert gw_hashes == [
                 %{hash: "0x5776aac4db7532eda5af049b441f2770cd37d264034d3be4e8cca11c3b59836b"}
               ]

        {:ok,
         %{
           logs: [
             %{
               account_id: 17544,
               data:
                 "0xb832b50000000000b832b50000000000000000000000000000000000000000000000000000000000",
               index: 0,
               service_flag: 2,
               transaction_hash:
                 "0x5776aac4db7532eda5af049b441f2770cd37d264034d3be4e8cca11c3b59836b",
               type: :polyjuice_system
             }
           ],
           sudt_pay_fees: [
             %{
               amount: 32_306_400_000_000_000_000,
               block_producer_address: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040",
               block_producer_registry_id: 2,
               from_address: "0xe2d73bf4e1306002811258417152a3eaa4cd4794",
               from_registry_id: 2,
               log_index: 3,
               transaction_hash:
                 "0x5776aac4db7532eda5af049b441f2770cd37d264034d3be4e8cca11c3b59836b",
               udt_id: 1
             }
           ],
           sudt_transfers: [
             %{
               amount: 101,
               from_address: "0xe2d73bf4e1306002811258417152a3eaa4cd4794",
               from_registry_id: 2,
               log_index: 0,
               to_address: "0x83963a90b74e165df914b53ed9a5e8b29f5550bf",
               to_registry_id: 2,
               transaction_hash:
                 "0x5776aac4db7532eda5af049b441f2770cd37d264034d3be4e8cca11c3b59836b",
               udt_id: 1
             }
           ]
         }}
      end)
      |> expect(:fetch_balances, fn [
                                      %{
                                        account_id: nil,
                                        eth_address: ^contract_address_hash,
                                        registry_address:
                                          "0x020000001400000083963a90b74e165df914b53ed9a5e8b29f5550bf",
                                        udt_id: 1,
                                        udt_script_hash:
                                          "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
                                      },
                                      %{
                                        account_id: nil,
                                        eth_address: ^user_address_hash,
                                        registry_address:
                                          "0x0200000014000000e2d73bf4e1306002811258417152a3eaa4cd4794",
                                        udt_id: 1,
                                        udt_script_hash:
                                          "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
                                      },
                                      %{
                                        account_id: nil,
                                        eth_address: ^register_address_hash,
                                        registry_address:
                                          "0x0200000014000000715ab282b873b79a7be8b0e8c13c4e8966a52040",
                                        udt_id: 1,
                                        udt_script_hash:
                                          "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
                                      }
                                    ] ->
        {:ok,
         %GodwokenRPC.Account.FetchedBalances{
           errors: [],
           params_list: [
             %{
               account_id: nil,
               address_hash: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040",
               udt_id: 1,
               udt_script_hash:
                 "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
               value: 1_314_789_835_175_333_437_765_997
             }
           ]
         }}
      end)
      |> expect(:fetch_balances, fn [
                                      %{
                                        account_id: 17544,
                                        eth_address: ^contract_address_hash,
                                        registry_address:
                                          "0x020000001400000083963a90b74e165df914b53ed9a5e8b29f5550bf",
                                        udt_id: 1,
                                        udt_script_hash:
                                          "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
                                      },
                                      %{
                                        account_id: 60691,
                                        eth_address: ^user_address_hash,
                                        registry_address:
                                          "0x0200000014000000e2d73bf4e1306002811258417152a3eaa4cd4794",
                                        udt_id: 1,
                                        udt_script_hash:
                                          "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
                                      }
                                    ] ->
        {:ok,
         %GodwokenRPC.Account.FetchedBalances{
           errors: [],
           params_list: [
             %{
               account_id: 17544,
               address_hash: "0x83963a90b74e165df914b53ed9a5e8b29f5550bf",
               udt_id: 1,
               udt_script_hash:
                 "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
               value: 0
             },
             %{
               account_id: 60691,
               address_hash: "0xe2d73bf4e1306002811258417152a3eaa4cd4794",
               udt_id: 1,
               udt_script_hash:
                 "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
               value: 1_231_321_520_394_985_843_894
             }
           ]
         }}
      end)
      |> expect(:fetch_eth_hash_by_gw_hashes, fn gw_tx_hashes ->
        assert gw_tx_hashes == [
                 %{
                   gw_tx_hash:
                     "0x5776aac4db7532eda5af049b441f2770cd37d264034d3be4e8cca11c3b59836b"
                 }
               ]

        {:ok,
         %GodwokenRPC.Transaction.FetchedEthHashByGwHashes{
           errors: [],
           params_list: [
             %{
               eth_hash: "0x09bed96bf6d7613dcda029895306ca658342417498c15e503d3aa931957c9025",
               gw_tx_hash: "0x5776aac4db7532eda5af049b441f2770cd37d264034d3be4e8cca11c3b59836b"
             }
           ]
         }}
      end)
      |> expect(:fetch_transaction_receipts, fn _params ->
        {:ok,
         %{
           logs: [
             %{
               address_hash: "0xad1a3af247fe9905b4c6204cfd44061569ea4207",
               block_hash: "0x0860e69974352af658dfa74a89d928cb313979ded9587c63b6ee90e4a7ffb768",
               block_number: 1,
               data: "0x0000000000000000000000000000000000000000000000000000000000000000",
               first_topic: "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
               fourth_topic: nil,
               index: 836,
               second_topic: "0x0000000000000000000000007652738288b6423b5e1b64112c8c4a3c0f28d315",
               third_topic: "0x000000000000000000000000ad1a3af247fe9905b4c6204cfd44061569ea4207",
               transaction_hash:
                 "0x09bed96bf6d7613dcda029895306ca658342417498c15e503d3aa931957c9025"
             }
           ],
           receipts: [
             %{
               created_contract_address_hash: "0x78c88768b72DB425836aE8abe93d35593F0d680c",
               cumulative_gas_used: 37_152_756,
               gas_used: 44388,
               status: :succeed,
               transaction_hash:
                 "0x09bed96bf6d7613dcda029895306ca658342417498c15e503d3aa931957c9025",
               transaction_index: 836
             }
           ]
         }}
      end)
      |> expect(:fetch_account_ids, fn params ->
        assert params == [
                 %{
                   script: %{
                     "args" =>
                       "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd804000000ad1a3af247fe9905b4c6204cfd44061569ea4207",
                     "code_hash" =>
                       "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
                     "hash_type" => "type"
                   },
                   script_hash:
                     "0x20e9af552e1e926e0fa25b3facaa4805cfa6f522200c1f8cfc57121edd737856"
                 }
               ]

        {:ok,
         %GodwokenRPC.Account.FetchedAccountIDs{
           errors: [],
           params_list: [
             %{
               id: 21252,
               script: %{
                 "args" =>
                   "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd804000000ad1a3af247fe9905b4c6204cfd44061569ea4207",
                 "code_hash" =>
                   "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
                 "hash_type" => "type"
               },
               script_hash: "0x20e9af552e1e926e0fa25b3facaa4805cfa6f522200c1f8cfc57121edd737856"
             }
           ]
         }}
      end)
      |> expect(:fetch_account_ids, fn params ->
        assert params == [
                 %{
                   script: %{
                     "args" =>
                       "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd80400000078c88768b72db425836ae8abe93d35593f0d680c",
                     "code_hash" =>
                       "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
                     "hash_type" => "type"
                   },
                   script_hash:
                     "0x1e8de1f76c27b01748e9e483e2a2866f4d5b553f03072f472b7de7fd1b10b60e"
                 }
               ]

        {:ok,
         %GodwokenRPC.Account.FetchedAccountIDs{
           errors: [],
           params_list: [
             %{
               id: 104_500,
               script: %{
                 "args" =>
                   "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd80400000078c88768b72db425836ae8abe93d35593f0d680c",
                 "code_hash" =>
                   "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
                 "hash_type" => "type"
               },
               script_hash: "0x1e8de1f76c27b01748e9e483e2a2866f4d5b553f03072f472b7de7fd1b10b60e"
             }
           ]
         }}
      end)

      assert GodwokenIndexer.Block.SyncWorker.fetch_and_import(1) == {:ok, 2}

      ## import account
      assert Account |> Repo.get(17544) |> Map.get(:eth_address) |> to_string() ==
               "0x83963a90b74e165df914b53ed9a5e8b29f5550bf"

      from_account = Account |> Repo.get(60691)

      assert from_account |> Map.get(:eth_address) |> to_string() ==
               "0xe2d73bf4e1306002811258417152a3eaa4cd4794"

      assert from_account.nonce == 1

      ## import gw log
      assert Repo.aggregate(SudtPayFee, :count) == 1
      assert Repo.aggregate(SudtTransfer, :count) == 1

      ## handle polyjuice tx
      t =
        Transaction
        |> Repo.get("0x5776aac4db7532eda5af049b441f2770cd37d264034d3be4e8cca11c3b59836b")

      assert t.eth_hash |> to_string() ==
               "0x09bed96bf6d7613dcda029895306ca658342417498c15e503d3aa931957c9025"

      assert Repo.aggregate(Log, :count) == 1
      assert Repo.aggregate(TokenTransfer, :count) == 1
      assert Repo.aggregate(Polyjuice, :count) == 1
      assert Repo.aggregate(CurrentBridgedUDTBalance, :count) == 3

      assert_enqueued(
        worker: GodwokenIndexer.Worker.ImportContractCode,
        args: %{"block_number" => 1, "address" => "0x78c88768b72DB425836aE8abe93d35593F0d680c"}
      )

      assert_enqueued(
        worker: GodwokenIndexer.Worker.CheckContractUDT,
        args: %{"address" => "0x78c88768b72DB425836aE8abe93d35593F0d680c"}
      )

      assert_enqueued(
        worker: GodwokenIndexer.Worker.UpdateUDTInfo,
        args: %{"address_hash" => "0xad1a3af247fe9905b4c6204cfd44061569ea4207"}
      )

      ## import block
      assert Repo.get(Block, "0x9dc70371157f6afcd36a76a00ec6cae7d64eae839af8d82af57230416d3e7a72").gas_used ==
               Decimal.new(11_875_000)
    end
  end

  test "import polyjuice creator", %{register_address_hash: register_address_hash} do
    insert(:user,
      id: 60691,
      eth_address: "0xe2d73bf4e1306002811258417152a3eaa4cd4794",
      registry_address: "0x0200000014000000e2d73bf4e1306002811258417152a3eaa4cd4794",
      script: %{
        "args" =>
          "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8e2d73bf4e1306002811258417152a3eaa4cd4794",
        "code_hash" => "0x07521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec0",
        "hash_type" => "type"
      },
      script_hash: "0x96b5a6edfb5a91efd18da50df5f243fe89598195a8a65ccc53edf4fd9849230a"
    )

    MockGodwokenRPC
    |> expect(
      :fetch_blocks_by_range,
      fn 1..1 ->
        {:ok,
         %GodwokenRPC.Blocks{
           blocks_params: [
             %{
               gas_limit: 11_875_000,
               gas_used: 11_875_000,
               hash: "0x9dc70371157f6afcd36a76a00ec6cae7d64eae839af8d82af57230416d3e7a72",
               logs_bloom:
                 "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
               number: 347_086,
               parent_hash: "0x841290cff9bada0105c45f1110ba692ee03980f765b19cf71ad1a875eabd6ad4",
               producer_address: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040",
               registry_id: 2,
               size: 368,
               status: :committed,
               timestamp: ~U[2022-09-06 01:35:48.892000Z],
               transaction_count: 1
             }
           ],
           transactions_params: [
             %{
               account_ids: [3],
               args:
                 "0x01000000910000000c0000007d00000071000000080000006900000010000000300000003100000007521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec00134000000702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd807e0f16e6fb1c72a74e058c577be24702aadd15b0200000000000000000000000000000000000000",
               block_hash: "0xc47b678db83ada6f680ee5cfa8fd27ed645685f6cd407c8a38928e8cfac085fb",
               block_number: 1,
               code_hash: "0x07521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec0",
               eth_hash: nil,
               fee_amount: 0,
               fee_registry_id: 2,
               from_account_id: 3,
               hash: "0x83e2a6dbeb483235f96b1b9155d4096ecd6a4920e5960adb03deaef0fd35dc08",
               hash_type: "type",
               index: 2,
               nonce: 7,
               script_args:
                 "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd807e0f16e6fb1c72a74e058c577be24702aadd15b",
               to_account_id: 0,
               type: :polyjuice_creator
             }
           ],
           withdrawal_params: [],
           errors: []
         }}
      end
    )
    |> expect(:fetch_gw_transaction_receipts, fn gw_hashes ->
      assert gw_hashes == [
               %{hash: "0x83e2a6dbeb483235f96b1b9155d4096ecd6a4920e5960adb03deaef0fd35dc08"}
             ]

      {:ok,
       %{
         logs: [
           %{
             account_id: 1,
             data:
               "0x0200000014000000715ab282b873b79a7be8b0e8c13c4e8966a520400200000014000000715ab282b873b79a7be8b0e8c13c4e8966a520400000000000000000000000000000000000000000000000000000000000000000",
             index: 0,
             service_flag: 1,
             transaction_hash:
               "0x83e2a6dbeb483235f96b1b9155d4096ecd6a4920e5960adb03deaef0fd35dc08",
             type: :sudt_pay_fee
           }
         ],
         sudt_pay_fees: [
           %{
             amount: 0,
             block_producer_address: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040",
             block_producer_registry_id: 2,
             from_address: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040",
             from_registry_id: 2,
             log_index: 0,
             transaction_hash:
               "0x83e2a6dbeb483235f96b1b9155d4096ecd6a4920e5960adb03deaef0fd35dc08",
             udt_id: 1
           }
         ],
         sudt_transfers: []
       }}
    end)
    |> expect(:fetch_balances, fn [
                                    %{
                                      account_id: nil,
                                      eth_address: ^register_address_hash,
                                      registry_address:
                                        "0x0200000014000000715ab282b873b79a7be8b0e8c13c4e8966a52040",
                                      udt_id: 1,
                                      udt_script_hash:
                                        "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
                                    }
                                  ] ->
      {:ok,
       %GodwokenRPC.Account.FetchedBalances{
         errors: [],
         params_list: [
           %{
             account_id: 17544,
             address_hash: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040",
             udt_id: 1,
             udt_script_hash:
               "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
             value: 1_231_321_520_394_985_843_894
           }
         ]
       }}
    end)
    |> expect(:fetch_account_ids, fn params ->
      assert params == [
               %{
                 script_hash:
                   "0x79e5cff3d76c164b49b4964b317a47fefafd3ffeee4faec6d305b72c2aa0b8e4",
                 script: nil
               }
             ]

      {:ok,
       %GodwokenRPC.Account.FetchedAccountIDs{
         errors: [],
         params_list: [
           %{
             script_hash: "0x79e5cff3d76c164b49b4964b317a47fefafd3ffeee4faec6d305b72c2aa0b8e4",
             script: nil,
             id: 52693
           }
         ]
       }}
    end)
    |> expect(:fetch_scripts, fn script_hashes ->
      assert script_hashes == [
               %{
                 id: 52693,
                 script_hash:
                   "0x79e5cff3d76c164b49b4964b317a47fefafd3ffeee4faec6d305b72c2aa0b8e4",
                 script: nil
               }
             ]

      {:ok,
       %GodwokenRPC.Account.FetchedScripts{
         errors: [],
         params_list: [
           %{
             id: 52693,
             script: %{
               "args" =>
                 "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd807e0f16e6fb1c72a74e058c577be24702aadd15b",
               "code_hash" =>
                 "0x07521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec0",
               "hash_type" => "type"
             },
             script_hash: "0x79e5cff3d76c164b49b4964b317a47fefafd3ffeee4faec6d305b72c2aa0b8e4"
           }
         ]
       }}
    end)

    assert GodwokenIndexer.Block.SyncWorker.fetch_and_import(1) == {:ok, 2}
    assert Repo.aggregate(PolyjuiceCreator, :count) == 1
  end

  test "import withdraw reqeusts", %{udt: udt} do
    user = insert(:user)
    user_script_hash = user.script_hash |> to_string()

    MockGodwokenRPC
    |> expect(:fetch_tip_block_number, fn -> {:ok, 1} end)
    |> expect(
      :fetch_blocks_by_range,
      fn 1..1 ->
        {:ok,
         %GodwokenRPC.Blocks{
           blocks_params: [
             %{
               gas_limit: 11_875_000,
               gas_used: 11_875_000,
               hash: "0x9dc70371157f6afcd36a76a00ec6cae7d64eae839af8d82af57230416d3e7a72",
               logs_bloom:
                 "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
               number: 347_086,
               parent_hash: "0x841290cff9bada0105c45f1110ba692ee03980f765b19cf71ad1a875eabd6ad4",
               producer_address: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040",
               registry_id: 2,
               size: 368,
               status: :committed,
               timestamp: ~U[2022-09-06 01:35:48.892000Z],
               transaction_count: 0
             }
           ],
           transactions_params: [],
           withdrawal_params: [
             %{
               account_script_hash: user_script_hash,
               amount: 0,
               block_hash: "0x76b0325592e894dcad9ac66bd6505d8f6f76ab0875b360e2b67ebdd89ab4317a",
               block_number: 3219,
               capacity: 40_000_000_000,
               chain_id: 71401,
               fee_amount: 0,
               hash: "0x3c4772eeef6d2c43b4ead9db7c049202d1f0b9e1bb075d08da1ab821e42a6859",
               inserted_at: ~N[2023-03-02 10:05:38],
               nonce: 0,
               owner_lock_hash:
                 "0x651e4345ce3a3a7c4fcb1f78dc8fac799836da84ac8bf7d6e09f63b428875317",
               registry_id: 2,
               sudt_script_hash:
                 "0x0000000000000000000000000000000000000000000000000000000000000000",
               udt_id: 1,
               updated_at: ~N[2023-03-02 10:05:38]
             }
           ],
           errors: []
         }}
      end
    )
    |> expect(:fetch_balances, fn params ->
      assert params == [
               %{
                 account_id: nil,
                 eth_address: user.eth_address,
                 registry_address: user.registry_address,
                 udt_id: 1,
                 udt_script_hash: to_string(udt.script_hash)
               }
             ]

      {:ok,
       %GodwokenRPC.Account.FetchedBalances{
         errors: [],
         params_list: [
           %{
             account_id: nil,
             address_hash: user.eth_address,
             udt_id: 1,
             udt_script_hash:
               "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
             value: 1_231_321_520_394_985_843_894
           }
         ]
       }}
    end)

    GodwokenIndexer.Block.SyncWorker.handle_info({:work, 1}, [])
    assert Repo.aggregate(WithdrawalRequest, :count) == 1
  end

  test "wait to import when not under tip block number" do
    MockGodwokenRPC
    |> expect(:fetch_tip_block_number, fn -> {:ok, 0} end)

    assert {:noreply, []} == GodwokenIndexer.Block.SyncWorker.handle_info({:work, 1}, [])
  end

  test "forked" do
    MockGodwokenRPC
    |> expect(:fetch_tip_block_number, fn -> {:ok, 1} end)
    |> expect(
      :fetch_blocks_by_range,
      fn 1..1 ->
        {:ok,
         %GodwokenRPC.Blocks{
           blocks_params: [
             %{
               gas_limit: 11_875_000,
               gas_used: 11_875_000,
               hash: "0x9dc70371157f6afcd36a76a00ec6cae7d64eae839af8d82af57230416d3e7a72",
               logs_bloom:
                 "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
               number: 347_086,
               parent_hash: "0x841290cff9bada0105c45f1110ba692ee03980f765b19cf71ad1a875eabd6ad6",
               producer_address: "0x715ab282b873b79a7be8b0e8c13c4e8966a52040",
               registry_id: 2,
               size: 368,
               status: :committed,
               timestamp: ~U[2022-09-06 01:35:48.892000Z],
               transaction_count: 0
             }
           ],
           transactions_params: [],
           withdrawal_params: [],
           errors: []
         }}
      end
    )

    assert_raise MatchError, "no match of right hand side value: {:error, :forked}", fn ->
      GodwokenIndexer.Block.SyncWorker.handle_info({:work, 1}, [])
    end

    assert Repo.aggregate(Block, :count) == 0
  end

  test "sync transaction trigger method_id and mehod_name update" do
    from_account = insert(:user)

    to_account = insert(:polyjuice_contract_account)

    transaction =
      insert(:transaction,
        from_account: from_account,
        to_account: to_account
      )

    abi = abi_contents()
    insert(:smart_contract, account: to_account, abi: abi)

    insert(:polyjuice,
      transaction: transaction,
      input: "0x40d097c3000000000000000000000000cc0af0af911dd40853b8c8dfee90b32f8d1ecad6"
    )

    txs_params = [
      %{hash: transaction.hash |> to_string(), to_account_id: transaction.to_account_id}
    ]

    return = hd(SyncWorker.add_method_id_and_name_to_tx_params(txs_params))
    assert match?(%{method_id: "0x40d097c3", method_name: "SafeMint"}, return)
  end

  defp abi_contents() do
    Jason.decode!(File.read!(Path.join(["test/support", "erc721_abi.json"])))
  end
end
