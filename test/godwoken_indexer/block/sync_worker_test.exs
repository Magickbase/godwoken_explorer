defmodule GodwokenIndexer.Block.SyncWorkerTest do
  use GodwokenExplorer.DataCase

  import Hammox
  import GodwokenExplorer.Factory

  alias GodwokenExplorer.{Account, Block, Repo, Transaction, Log, TokenTransfer, Polyjuice}
  alias GodwokenExplorer.GW.{SudtPayFee, SudtTransfer}
  alias GodwokenExplorer.Account.CurrentBridgedUDTBalance
  alias GodwokenIndexer.Block.SyncWorker

  setup do
    insert(:block,
      hash: "0x841290cff9bada0105c45f1110ba692ee03980f765b19cf71ad1a875eabd6ad4",
      number: 0
    )

    insert(:ckb_udt)
    insert(:ckb_account)
    insert(:block_producer)
    :ok
  end

  setup :verify_on_exit!

  describe "import_range/2" do
    test "import a block succeed" do
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
                 block_number: 347_086,
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
      |> expect(:fetch_balances, fn _params ->
        {:ok,
         %GodwokenRPC.Account.FetchedBalances{
           errors: [],
           params_list: [
             %{
               account_id: nil,
               address_hash: "0x83963a90b74e165df914b53ed9a5e8b29f5550bf",
               udt_id: 1,
               udt_script_hash:
                 "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
               value: 0
             },
             %{
               account_id: nil,
               address_hash: "0xe2d73bf4e1306002811258417152a3eaa4cd4794",
               udt_id: 1,
               udt_script_hash:
                 "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
               value: 1_231_321_520_394_985_843_894
             },
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
               block_number: 79604,
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
               created_contract_address_hash: nil,
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
      |> expect(:fetch_account_id, fn script_hash ->
        assert script_hash == "0x20e9af552e1e926e0fa25b3facaa4805cfa6f522200c1f8cfc57121edd737856"

        {:ok, 21252}
      end)
      |> expect(:fetch_nonce, fn id ->
        assert id == 21252

        10
      end)
      |> expect(:fetch_script, fn script_hash ->
        assert script_hash == "0x20e9af552e1e926e0fa25b3facaa4805cfa6f522200c1f8cfc57121edd737856"

        {:ok,
         %{
           "args" =>
             "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd804000000ad1a3af247fe9905b4c6204cfd44061569ea4207",
           "code_hash" => "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
           "hash_type" => "type"
         }}
      end)
      |> expect(:fetch_script_hash, fn params ->
        assert params == %{account_id: 21252}

        {:ok, "0x20e9af552e1e926e0fa25b3facaa4805cfa6f522200c1f8cfc57121edd737856"}
      end)

      assert GodwokenIndexer.Block.SyncWorker.fetch_and_import(1) == {:ok, 2}

      assert Account |> Repo.get(17544) |> Map.get(:eth_address) |> to_string() ==
               "0x83963a90b74e165df914b53ed9a5e8b29f5550bf"

      from_account = Account |> Repo.get(60691)

      assert from_account |> Map.get(:eth_address) |> to_string() ==
               "0xe2d73bf4e1306002811258417152a3eaa4cd4794"

      assert from_account.nonce == 1

      assert Repo.aggregate(SudtPayFee, :count) == 1
      assert Repo.aggregate(SudtTransfer, :count) == 1
      assert Repo.aggregate(CurrentBridgedUDTBalance, :count) == 3

      t =
        Transaction
        |> Repo.get("0x5776aac4db7532eda5af049b441f2770cd37d264034d3be4e8cca11c3b59836b")

      assert t.eth_hash |> to_string() ==
               "0x09bed96bf6d7613dcda029895306ca658342417498c15e503d3aa931957c9025"

      assert Repo.aggregate(Log, :count) == 1
      assert Repo.aggregate(TokenTransfer, :count) == 1

      assert Repo.get(Block, "0x9dc70371157f6afcd36a76a00ec6cae7d64eae839af8d82af57230416d3e7a72").gas_used ==
               Decimal.new(11_875_000)

      assert Repo.aggregate(Polyjuice, :count) == 1
    end
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
    [
      %{"inputs" => [], "stateMutability" => "nonpayable", "type" => "constructor"},
      %{
        "anonymous" => false,
        "inputs" => [
          %{
            "indexed" => true,
            "internalType" => "address",
            "name" => "owner",
            "type" => "address"
          },
          %{
            "indexed" => true,
            "internalType" => "address",
            "name" => "approved",
            "type" => "address"
          },
          %{
            "indexed" => true,
            "internalType" => "uint256",
            "name" => "tokenId",
            "type" => "uint256"
          }
        ],
        "name" => "Approval",
        "type" => "event"
      },
      %{
        "anonymous" => false,
        "inputs" => [
          %{
            "indexed" => true,
            "internalType" => "address",
            "name" => "owner",
            "type" => "address"
          },
          %{
            "indexed" => true,
            "internalType" => "address",
            "name" => "operator",
            "type" => "address"
          },
          %{
            "indexed" => false,
            "internalType" => "bool",
            "name" => "approved",
            "type" => "bool"
          }
        ],
        "name" => "ApprovalForAll",
        "type" => "event"
      },
      %{
        "anonymous" => false,
        "inputs" => [
          %{
            "indexed" => true,
            "internalType" => "address",
            "name" => "previousOwner",
            "type" => "address"
          },
          %{
            "indexed" => true,
            "internalType" => "address",
            "name" => "newOwner",
            "type" => "address"
          }
        ],
        "name" => "OwnershipTransferred",
        "type" => "event"
      },
      %{
        "anonymous" => false,
        "inputs" => [
          %{
            "indexed" => true,
            "internalType" => "address",
            "name" => "from",
            "type" => "address"
          },
          %{
            "indexed" => true,
            "internalType" => "address",
            "name" => "to",
            "type" => "address"
          },
          %{
            "indexed" => true,
            "internalType" => "uint256",
            "name" => "tokenId",
            "type" => "uint256"
          }
        ],
        "name" => "Transfer",
        "type" => "event"
      },
      %{
        "inputs" => [
          %{"internalType" => "address", "name" => "to", "type" => "address"},
          %{"internalType" => "uint256", "name" => "tokenId", "type" => "uint256"}
        ],
        "name" => "approve",
        "outputs" => [],
        "stateMutability" => "nonpayable",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "address", "name" => "owner", "type" => "address"}
        ],
        "name" => "balanceOf",
        "outputs" => [
          %{"internalType" => "uint256", "name" => "", "type" => "uint256"}
        ],
        "stateMutability" => "view",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "uint256", "name" => "tokenId", "type" => "uint256"}
        ],
        "name" => "burn",
        "outputs" => [],
        "stateMutability" => "nonpayable",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "uint256", "name" => "tokenId", "type" => "uint256"}
        ],
        "name" => "getApproved",
        "outputs" => [
          %{"internalType" => "address", "name" => "", "type" => "address"}
        ],
        "stateMutability" => "view",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "address", "name" => "owner", "type" => "address"},
          %{"internalType" => "address", "name" => "operator", "type" => "address"}
        ],
        "name" => "isApprovedForAll",
        "outputs" => [%{"internalType" => "bool", "name" => "", "type" => "bool"}],
        "stateMutability" => "view",
        "type" => "function"
      },
      %{
        "inputs" => [],
        "name" => "name",
        "outputs" => [
          %{"internalType" => "string", "name" => "", "type" => "string"}
        ],
        "stateMutability" => "view",
        "type" => "function"
      },
      %{
        "inputs" => [],
        "name" => "owner",
        "outputs" => [
          %{"internalType" => "address", "name" => "", "type" => "address"}
        ],
        "stateMutability" => "view",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "uint256", "name" => "tokenId", "type" => "uint256"}
        ],
        "name" => "ownerOf",
        "outputs" => [
          %{"internalType" => "address", "name" => "", "type" => "address"}
        ],
        "stateMutability" => "view",
        "type" => "function"
      },
      %{
        "inputs" => [],
        "name" => "renounceOwnership",
        "outputs" => [],
        "stateMutability" => "nonpayable",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "address", "name" => "to", "type" => "address"}
        ],
        "name" => "safeMint",
        "outputs" => [],
        "stateMutability" => "nonpayable",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "address", "name" => "from", "type" => "address"},
          %{"internalType" => "address", "name" => "to", "type" => "address"},
          %{"internalType" => "uint256", "name" => "tokenId", "type" => "uint256"}
        ],
        "name" => "safeTransferFrom",
        "outputs" => [],
        "stateMutability" => "nonpayable",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "address", "name" => "from", "type" => "address"},
          %{"internalType" => "address", "name" => "to", "type" => "address"},
          %{"internalType" => "uint256", "name" => "tokenId", "type" => "uint256"},
          %{"internalType" => "bytes", "name" => "data", "type" => "bytes"}
        ],
        "name" => "safeTransferFrom",
        "outputs" => [],
        "stateMutability" => "nonpayable",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "address", "name" => "operator", "type" => "address"},
          %{"internalType" => "bool", "name" => "approved", "type" => "bool"}
        ],
        "name" => "setApprovalForAll",
        "outputs" => [],
        "stateMutability" => "nonpayable",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "bytes4", "name" => "interfaceId", "type" => "bytes4"}
        ],
        "name" => "supportsInterface",
        "outputs" => [%{"internalType" => "bool", "name" => "", "type" => "bool"}],
        "stateMutability" => "view",
        "type" => "function"
      },
      %{
        "inputs" => [],
        "name" => "symbol",
        "outputs" => [
          %{"internalType" => "string", "name" => "", "type" => "string"}
        ],
        "stateMutability" => "view",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "uint256", "name" => "tokenId", "type" => "uint256"}
        ],
        "name" => "tokenURI",
        "outputs" => [
          %{"internalType" => "string", "name" => "", "type" => "string"}
        ],
        "stateMutability" => "view",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "address", "name" => "from", "type" => "address"},
          %{"internalType" => "address", "name" => "to", "type" => "address"},
          %{"internalType" => "uint256", "name" => "tokenId", "type" => "uint256"}
        ],
        "name" => "transferFrom",
        "outputs" => [],
        "stateMutability" => "nonpayable",
        "type" => "function"
      },
      %{
        "inputs" => [
          %{"internalType" => "address", "name" => "newOwner", "type" => "address"}
        ],
        "name" => "transferOwnership",
        "outputs" => [],
        "stateMutability" => "nonpayable",
        "type" => "function"
      }
    ]
  end
end
