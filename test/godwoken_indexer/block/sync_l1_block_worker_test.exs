defmodule GodwokenIndexer.Block.SyncL1WorkerTest do
  use GodwokenExplorer.DataCase

  import Hammox
  import GodwokenExplorer.Factory

  alias GodwokenExplorer.Account.CurrentBridgedUDTBalance

  alias GodwokenExplorer.{
    DepositHistory,
    Repo,
    WithdrawalHistory
  }

  setup do
    insert(:block)
    insert(:ckb_udt)
    insert(:ckb_account)
    :ok
  end

  setup :verify_on_exit!

  test "forked" do
    insert(:check_info,
      block_hash: "0x7503c113ba99e34a4d6bc33e9fbf5ad7d8b23d10ffe6cbe13ea3b4377f1e7a13",
      tip_block_number: 5_303_360
    )

    MockGodwokenRPC
    |> expect(:fetch_l1_tip_block_number, fn ->
      {:ok, 5_303_360}
    end)
    |> expect(:fetch_l1_blocks, fn _range ->
      {:ok,
       %GodwokenRPC.CKBIndexer.FetchedBlocks{
         params_list: [
           %{
             block: %{
               "header" => %{
                 "compact_target" => "0x1e015555",
                 "dao" => "0x30563e87f420a12eaeea81e7f28623004bd82ce29300000000b2b49f02fbfe06",
                 "epoch" => "0x3e8000b000000",
                 "extra_hash" =>
                   "0x0000000000000000000000000000000000000000000000000000000000000000",
                 "hash" => "0x18b8cda2aecd83b25df917e28fde1bff31f032085463dd805074df0e68edeec6",
                 "nonce" => "0x2afa31617052a71d4459a64d57e79254",
                 "number" => "0xb",
                 "parent_hash" =>
                   "0x4bdff7e0bd58c9cca74af5a51792e8119958ab6b5e5cacbb8f8c615e5c4b61dc",
                 "proposals_hash" =>
                   "0x0000000000000000000000000000000000000000000000000000000000000000",
                 "timestamp" => "0x1723b9a054e",
                 "transactions_root" =>
                   "0xa36b11a686863d353d9f4f638b74ebcbeba8e765ceec7186e2f3dcb0c2ec64e2",
                 "version" => "0x0"
               },
               "proposals" => [],
               "transactions" => [
                 %{
                   "cell_deps" => [],
                   "hash" => "0x4298daf91148df9093c844d2ae7d16bee6b74e7ab1ccccd108ce834d1ca1a56c",
                   "header_deps" => [],
                   "inputs" => [
                     %{
                       "previous_output" => %{
                         "index" => "0xffffffff",
                         "tx_hash" =>
                           "0x0000000000000000000000000000000000000000000000000000000000000000"
                       },
                       "since" => "0xb"
                     }
                   ],
                   "outputs" => [],
                   "outputs_data" => [],
                   "version" => "0x0",
                   "witnesses" => [
                     "0x5d0000000c00000055000000490000001000000030000000310000009bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce80114000000da648442dbb7347e467d1d09da13e5cd3a0ef0e104000000deadbeef"
                   ]
                 }
               ],
               "uncles" => []
             },
             block_number: 11
           }
         ],
         errors: []
       }}
    end)

    assert catch_throw(
             GodwokenIndexer.Block.SyncL1BlockWorker.handle_info({:bind_deposit_work, 11}, [])
           ) ==
             :rollback
  end

  describe "sync deposit l1 block" do
    setup do
      insert(:check_info,
        block_hash: "0x7503c113ba99e34a4d6bc33e9fbf5ad7d8b23d10ffe6cbe13ea3b4377f1e7a13",
        tip_block_number: 5_303_360
      )

      :ok
    end

    test "sync l1 block successfully" do
      MockGodwokenRPC
      |> expect(:fetch_l1_tip_block_number, fn ->
        {:ok, 5_303_360}
      end)
      |> expect(:fetch_l1_blocks, fn _range ->
        {:ok,
         %GodwokenRPC.CKBIndexer.FetchedBlocks{
           params_list: [
             %{
               block: %{
                 "header" => %{
                   "compact_target" => "0x1d068b02",
                   "dao" => "0xc6e7dda2bdf5b63df0fcd9606c062600ef5ca59e7f2d290300085e00d7d93a08",
                   "epoch" => "0x708068d0010c5",
                   "extra_hash" =>
                     "0x0000000000000000000000000000000000000000000000000000000000000000",
                   "hash" => "0xd414fe6506e43830e03d3062fd9528265b7e124a050576d8f7e0ceaa42934958",
                   "nonce" => "0x8d389a240f258e8425a4b46f5a1dce12",
                   "number" => "0x50ebdc",
                   "parent_hash" =>
                     "0x7503c113ba99e34a4d6bc33e9fbf5ad7d8b23d10ffe6cbe13ea3b4377f1e7a13",
                   "proposals_hash" =>
                     "0x0000000000000000000000000000000000000000000000000000000000000000",
                   "timestamp" => "0x180a6ad6331",
                   "transactions_root" =>
                     "0x39bbd5b5aba6ce31e825f532f39c2a579d5883f56bca2e0a033eb38c531b4547",
                   "version" => "0x0"
                 },
                 "proposals" => [],
                 "transactions" => [
                   %{
                     "cell_deps" => [],
                     "hash" =>
                       "0xd60cba87f988cef80b1527973d9c313149a908da16e435c07fa23df896f89cab",
                     "header_deps" => [],
                     "inputs" => [
                       %{
                         "previous_output" => %{
                           "index" => "0xffffffff",
                           "tx_hash" =>
                             "0x0000000000000000000000000000000000000000000000000000000000000000"
                         },
                         "since" => "0x50ebdc"
                       }
                     ],
                     "outputs" => [
                       %{
                         "capacity" => "0x19dd9215b1",
                         "lock" => %{
                           "args" => "0xc93777a8f275fb6990dec7895efb9d207227ab2f",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       }
                     ],
                     "outputs_data" => ["0x"],
                     "version" => "0x0",
                     "witnesses" => [
                       "0x7a0000000c00000055000000490000001000000030000000310000009bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce80114000000da648442dbb7347e467d1d09da13e5cd3a0ef0e121000000302e3130332e3020286537373133386520323032322d30342d31312920deadbeef"
                     ]
                   },
                   %{
                     "cell_deps" => [
                       %{
                         "dep_type" => "dep_group",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xd48ebd7c52ee3793ccaeef9ab40c29281c1fc4e901fb52b286fc1af74532f1cb"
                         }
                       },
                       %{
                         "dep_type" => "dep_group",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37"
                         }
                       }
                     ],
                     "hash" =>
                       "0x6fa4cb496f1837ecdbd08800e5f1a579e2ef92a5637934cd49c346f72349fc53",
                     "header_deps" => [],
                     "inputs" => [
                       %{
                         "previous_output" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0x1b7306d1d2a7f54539c68511d924bbf17ef8648cd0dba5be15178172e5ec11ee"
                         },
                         "since" => "0x0"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x1",
                           "tx_hash" =>
                             "0xb8f9427baed0d2a28da87d5ccc64008a552ce9b136b5b6dc4e3ca7dfacfebbed"
                         },
                         "since" => "0x4000000062787dee"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x2",
                           "tx_hash" =>
                             "0x51e35eaa353dda189eeccdca0d2d78e4cfc0153d40d975235f702d9c6e3edeff"
                         },
                         "since" => "0x0"
                       }
                     ],
                     "outputs" => [
                       %{
                         "capacity" => "0x9502f9000",
                         "lock" => %{
                           "args" => "0x6a21bc1b72d1e654f8e2ded400cffa46075494c6",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => %{
                           "args" => "0x01",
                           "code_hash" =>
                             "0x554cff969f3148e3c620749384004e9692e67c429f621554d139b505a281c7b8",
                           "hash_type" => "type"
                         }
                       },
                       %{
                         "capacity" => "0x9502f9000",
                         "lock" => %{
                           "args" => "0x6a21bc1b72d1e654f8e2ded400cffa46075494c6",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => %{
                           "args" => "0x01",
                           "code_hash" =>
                             "0x96248cdefb09eed910018a847cfb51ad044c2d7db650112931760e3ef34a7e9a",
                           "hash_type" => "type"
                         }
                       },
                       %{
                         "capacity" => "0x79a6820a198",
                         "lock" => %{
                           "args" => "0x6a21bc1b72d1e654f8e2ded400cffa46075494c6",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       }
                     ],
                     "outputs_data" => ["0x0b0c", "0x0b010000000062787dee", "0x"],
                     "version" => "0x0",
                     "witnesses" => [
                       "0x55000000100000005500000055000000410000005a568cb8960697aae35bb4349807a1a518a7ffc632a282fd39b3cda8e287d31f19ce8919b19a6bb25014c56fbc5c75f835906ca0619481055b7c0e3ac0452a6400",
                       "0x10000000100000001000000010000000",
                       "0x10000000100000001000000010000000"
                     ]
                   },
                   %{
                     "cell_deps" => [
                       %{
                         "dep_type" => "dep_group",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xd48ebd7c52ee3793ccaeef9ab40c29281c1fc4e901fb52b286fc1af74532f1cb"
                         }
                       },
                       %{
                         "dep_type" => "dep_group",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37"
                         }
                       }
                     ],
                     "hash" =>
                       "0x23ed627c88711d5fc1b2289d7b40b3921176f7dbe5b37782cf8bcb4eb6ff3c20",
                     "header_deps" => [],
                     "inputs" => [
                       %{
                         "previous_output" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0x589cf9d4c8d295ec9307ec06f0d5e0ef5a10db997ff8665865151464de8bd758"
                         },
                         "since" => "0x0"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x1",
                           "tx_hash" =>
                             "0xb3efa41ef85845643043736d826a0d6e45098cca1fa19876cc58115e6b2256df"
                         },
                         "since" => "0x50ebd9"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x2",
                           "tx_hash" =>
                             "0x5524e50f9d8103321275449227c4be5ec455ea71e80fb60b24685cb5ccc8d9d6"
                         },
                         "since" => "0x0"
                       }
                     ],
                     "outputs" => [
                       %{
                         "capacity" => "0x9502f9000",
                         "lock" => %{
                           "args" => "0xa897829e60ee4e3fb0e4abe65549ec4a5ddafad7",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => %{
                           "args" => "0x02",
                           "code_hash" =>
                             "0x554cff969f3148e3c620749384004e9692e67c429f621554d139b505a281c7b8",
                           "hash_type" => "type"
                         }
                       },
                       %{
                         "capacity" => "0x9502f9000",
                         "lock" => %{
                           "args" => "0xa897829e60ee4e3fb0e4abe65549ec4a5ddafad7",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => %{
                           "args" => "0x02",
                           "code_hash" =>
                             "0x96248cdefb09eed910018a847cfb51ad044c2d7db650112931760e3ef34a7e9a",
                           "hash_type" => "type"
                         }
                       },
                       %{
                         "capacity" => "0x79a62e65420",
                         "lock" => %{
                           "args" => "0xa897829e60ee4e3fb0e4abe65549ec4a5ddafad7",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       }
                     ],
                     "outputs_data" => ["0x0b0c", "0x0b02000000000050ebd9", "0x"],
                     "version" => "0x0",
                     "witnesses" => [
                       "0x5500000010000000550000005500000041000000ca09f8db984bc79528e7989f0fc8f85cc6772051d63473176c82a8b0c874af221b70d7f02f5e4b9df02ddc8e164a8275f8b766648d03c1ab892ebadb2bf5c07500",
                       "0x10000000100000001000000010000000",
                       "0x10000000100000001000000010000000"
                     ]
                   },
                   %{
                     "cell_deps" => [
                       %{
                         "dep_type" => "dep_group",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xd48ebd7c52ee3793ccaeef9ab40c29281c1fc4e901fb52b286fc1af74532f1cb"
                         }
                       },
                       %{
                         "dep_type" => "dep_group",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37"
                         }
                       }
                     ],
                     "hash" =>
                       "0x072a559d16acc9896eecc1fdc40c3e5ef7fb643608107304ed23eea99f938050",
                     "header_deps" => [],
                     "inputs" => [
                       %{
                         "previous_output" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0x0c986e76ddf97f88499380558cd7dd19c7f67432c031bf986222ff1d9f08c97c"
                         },
                         "since" => "0x0"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x1",
                           "tx_hash" =>
                             "0x9e17ceb3e4ac541aec508bf869c39f0eb78e778dd96ef5ac712683dff888aadf"
                         },
                         "since" => "0x0"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x2",
                           "tx_hash" =>
                             "0x1383c3c780e9698cc8af524995cf67a2f22ebef4defa0f354c266881daf877ee"
                         },
                         "since" => "0x0"
                       }
                     ],
                     "outputs" => [
                       %{
                         "capacity" => "0x9502f9000",
                         "lock" => %{
                           "args" => "0xb12e3692d401c331f6d1f1efcb24d510296c4a6a",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => %{
                           "args" => "0x00",
                           "code_hash" =>
                             "0x554cff969f3148e3c620749384004e9692e67c429f621554d139b505a281c7b8",
                           "hash_type" => "type"
                         }
                       },
                       %{
                         "capacity" => "0x9502f9000",
                         "lock" => %{
                           "args" => "0xb12e3692d401c331f6d1f1efcb24d510296c4a6a",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => %{
                           "args" => "0x00",
                           "code_hash" =>
                             "0x96248cdefb09eed910018a847cfb51ad044c2d7db650112931760e3ef34a7e9a",
                           "hash_type" => "type"
                         }
                       },
                       %{
                         "capacity" => "0x6f9a507d0",
                         "lock" => %{
                           "args" => "0xb12e3692d401c331f6d1f1efcb24d510296c4a6a",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       }
                     ],
                     "outputs_data" => ["0x070c", "0x070000000000000020a3", "0x"],
                     "version" => "0x0",
                     "witnesses" => [
                       "0x55000000100000005500000055000000410000005bdff33546984c1a7983b0b6c41624b9a41df85bcaf5b4fed4ee90d8b6e4c9bc563fca46a1c670609f1d0258a0ae1d212950fcca49edcd051f52c1d6ebcad20c00",
                       "0x10000000100000001000000010000000",
                       "0x10000000100000001000000010000000"
                     ]
                   },
                   %{
                     "cell_deps" => [
                       %{
                         "dep_type" => "code",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0x97d7df5fed47428465b94bd716714b10f3646beed1ad717989d89db47bac6a2a"
                         }
                       },
                       %{
                         "dep_type" => "code",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xa8c2fe2aaaf405b2b1fd33dd63adc4c514a3d1f6dd1a64244489ad75c51a5d14"
                         }
                       },
                       %{
                         "dep_type" => "dep_group",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37"
                         }
                       }
                     ],
                     "hash" =>
                       "0xa07b82388517575a7fce0bfdc592208bda92bf6188432b1dc18399aa0b45ae6e",
                     "header_deps" => [],
                     "inputs" => [
                       %{
                         "previous_output" => %{
                           "index" => "0x35",
                           "tx_hash" =>
                             "0x97d7df5fed47428465b94bd716714b10f3646beed1ad717989d89db47bac6a2a"
                         },
                         "since" => "0x0"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x1",
                           "tx_hash" =>
                             "0x3141e9a9dd0001bab27b72e2678ce60bfce66a0bf3e4bb45ece483969c3f3cdd"
                         },
                         "since" => "0x0"
                       }
                     ],
                     "outputs" => [
                       %{
                         "capacity" => "0x174876e800",
                         "lock" => %{
                           "args" =>
                             "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8a900000014000000340000009d000000a500000067a7bfc639c348f7bfb833825304cfa79d7a02bc4fb6d7c2712b1400566b87636900000010000000300000003100000007521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec00134000000702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8890616016250e494f2da742496c8ec491546525f813a0900000000c002000000",
                           "code_hash" =>
                             "0x50704b84ecb4c4b12b43c7acb260ddd69171c21b4c0ba15f3c469b7d143f6f18",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       },
                       %{
                         "capacity" => "0xcefc874bf4",
                         "lock" => %{
                           "args" => "0xdb54bada928e9b83e952dba4acec57e9f7049639",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       }
                     ],
                     "outputs_data" => ["0x", "0x"],
                     "version" => "0x0",
                     "witnesses" => [
                       "0x1c000000100000001c0000001c000000080000000300000004000000",
                       "0x5500000010000000550000005500000041000000195404140d91b97f3da3a70157696d22d74418eb88eeeb81c407693b667377410ece5313cfbba8a07749e5ad7efb7cc47b87dacf3929b3cfa4b2389a01c5810900"
                     ]
                   }
                 ],
                 "uncles" => []
               },
               block_number: 5_303_260
             }
           ],
           errors: []
         }}
      end)
      |> expect(:fetch_account_ids, fn _params ->
        {:ok,
         %GodwokenRPC.Account.FetchedAccountIDs{
           errors: [],
           params_list: [
             %{
               script_hash: "0x126a5078e98951de423a142fcd204240d4d4f1216a14e232356884cb054e32d0",
               script: nil,
               id: 55
             }
           ]
         }}
      end)
      |> expect(:fetch_scripts, fn _script_hashes ->
        {:ok,
         %GodwokenRPC.Account.FetchedScripts{
           errors: [],
           params_list: [
             %{
               script_hash: "0x126a5078e98951de423a142fcd204240d4d4f1216a14e232356884cb054e32d0",
               script: %{
                 "args" =>
                   "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8890616016250e494f2da742496c8ec491546525f",
                 "code_hash" =>
                   "0x07521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec0",
                 "hash_type" => "type"
               },
               id: 55
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
               account_id: 55,
               address_hash: "0x890616016250e494f2da742496c8ec491546525f",
               udt_id: 1,
               udt_script_hash:
                 "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
               value: 1000
             }
           ]
         }}
      end)

      GodwokenIndexer.Block.SyncL1BlockWorker.handle_info({:bind_deposit_work, 5_303_260}, [])
      assert DepositHistory |> Repo.aggregate(:count) == 1
      assert CurrentBridgedUDTBalance |> Repo.aggregate(:count) == 1
    end
  end

  describe "withdrawal" do
    setup do
      insert(:check_info,
        block_hash: "0x5be03b53bc1f51ef866a5bd53f7a85a3d4be9311e23601541b5347239a009b0c",
        tip_block_number: 5_305_463
      )

      insert(:user,
        id: 55,
        eth_address: "0x890616016250e494f2da742496c8ec491546525f",
        script_hash: "0x126a5078e98951de423a142fcd204240d4d4f1216a14e232356884cb054e32d0",
        script: %{
          "args" =>
            "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8890616016250e494f2da742496c8ec491546525f",
          "code_hash" => "0x07521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec0",
          "hash_type" => "type"
        },
        registry_address: "0x0200000014000000890616016250e494f2da742496c8ec491546525f"
      )

      :ok
    end

    test "sync l1 block successfully" do
      MockGodwokenRPC
      |> expect(:fetch_l1_tip_block_number, fn ->
        {:ok, 5_305_463}
      end)
      |> expect(:fetch_l1_blocks, fn _range ->
        {:ok,
         %GodwokenRPC.CKBIndexer.FetchedBlocks{
           params_list: [
             %{
               block: %{
                 "header" => %{
                   "compact_target" => "0x1d0691fc",
                   "dao" => "0x49dfe2a5bc02b83dee21878e9406260005cda281036629030066385ac6523b08",
                   "epoch" => "0x70800b40010c7",
                   "extra_hash" =>
                     "0x0000000000000000000000000000000000000000000000000000000000000000",
                   "hash" => "0xb766200e556116da66ea21b3c5e04aafcda1c4fd0c3a8d541423838d75d12752",
                   "nonce" => "0xb4a27b56ca16370f90aacce7b319a5eb",
                   "number" => "0x50f413",
                   "parent_hash" =>
                     "0x5be03b53bc1f51ef866a5bd53f7a85a3d4be9311e23601541b5347239a009b0c",
                   "proposals_hash" =>
                     "0xef8906a4f8e035a4660209a9486f5f44c733764d3cbfc417282d355f74ee83a2",
                   "timestamp" => "0x180a7ae8dd7",
                   "transactions_root" =>
                     "0xa032937d36d91c8871abccee18915342b76fc02b896de2de77bfb012a5711617",
                   "version" => "0x0"
                 },
                 "proposals" => [
                   "0x4b115577db860675e9dc",
                   "0x9c5de81bcf8ec81a7cd0",
                   "0x859e0a402c0f971d98c6",
                   "0xe9f924f805d271d1bd46"
                 ],
                 "transactions" => [
                   %{
                     "cell_deps" => [],
                     "hash" =>
                       "0x445af51c09c2ffe39c62cdfaef86db2633d8455577ece4bd8aabdcddf35f6536",
                     "header_deps" => [],
                     "inputs" => [
                       %{
                         "previous_output" => %{
                           "index" => "0xffffffff",
                           "tx_hash" =>
                             "0x0000000000000000000000000000000000000000000000000000000000000000"
                         },
                         "since" => "0x50f413"
                       }
                     ],
                     "outputs" => [
                       %{
                         "capacity" => "0x19dd9cee5f",
                         "lock" => %{
                           "args" => "0xda648442dbb7347e467d1d09da13e5cd3a0ef0e1",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       }
                     ],
                     "outputs_data" => ["0x"],
                     "version" => "0x0",
                     "witnesses" => [
                       "0x7e0000000c00000055000000490000001000000030000000310000009bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce80114000000c93777a8f275fb6990dec7895efb9d207227ab2f25000000302e3130322e302d70726520286632333539386620323032322d30342d30372920deadbeef"
                     ]
                   },
                   %{
                     "cell_deps" => [
                       %{
                         "dep_type" => "dep_group",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37"
                         }
                       },
                       %{
                         "dep_type" => "code",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xbcd73881ba53f1cd95d0c855395c4ffe6f54e041765d9ab7602d48a7cb71612e"
                         }
                       },
                       %{
                         "dep_type" => "code",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0x9154df4f7336402114d04495175b37390ce86a4906d2d4001cf02c3e6d97f39c"
                         }
                       },
                       %{
                         "dep_type" => "code",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0x053fdb4ed3181eab3a3a5f05693b53a8cdec0a24569e16369f444bac48be7de9"
                         }
                       },
                       %{
                         "dep_type" => "code",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0x7aed145beb6984fff008ca6224d0726d06a19959c4f01d15e49942d76e28747a"
                         }
                       },
                       %{
                         "dep_type" => "code",
                         "out_point" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0xcd52d714ddea04d2917892f16d47cbd0bbbb7d9ba281233ec4021f79fc34bccc"
                         }
                       }
                     ],
                     "hash" =>
                       "0xc6c8db33783a102aa04bb827885c3654b297ade9387adca6edb0e372cc3a199b",
                     "header_deps" => [],
                     "inputs" => [
                       %{
                         "previous_output" => %{
                           "index" => "0x0",
                           "tx_hash" =>
                             "0x90a1b6f8f0b0b5260f0ac23fdd05dbbd4d1425a38399fd8dd5d632aaa5c3d7fb"
                         },
                         "since" => "0x400000006278bf8b"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x1",
                           "tx_hash" =>
                             "0x90a1b6f8f0b0b5260f0ac23fdd05dbbd4d1425a38399fd8dd5d632aaa5c3d7fb"
                         },
                         "since" => "0x0"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x2",
                           "tx_hash" =>
                             "0x90a1b6f8f0b0b5260f0ac23fdd05dbbd4d1425a38399fd8dd5d632aaa5c3d7fb"
                         },
                         "since" => "0x0"
                       },
                       %{
                         "previous_output" => %{
                           "index" => "0x3",
                           "tx_hash" =>
                             "0x90a1b6f8f0b0b5260f0ac23fdd05dbbd4d1425a38399fd8dd5d632aaa5c3d7fb"
                         },
                         "since" => "0x0"
                       }
                     ],
                     "outputs" => [
                       %{
                         "capacity" => "0x7676d7e00",
                         "lock" => %{
                           "args" => "0x00c267a8b93cdae15fb06325f11a72b1047bd4d33c00",
                           "code_hash" =>
                             "0x79f90bb5e892d80dd213439eeab551120eb417678824f282b4ffb5f21bad2e1e",
                           "hash_type" => "type"
                         },
                         "type" => %{
                           "args" =>
                             "0x86c7429247beba7ddd6e4361bcdfc0510b0b644131e2afb7e486375249a01802",
                           "code_hash" =>
                             "0x1e44736436b406f8e48a30dfbddcf044feb0c9eebfe63b0f81cb5bb727d84854",
                           "hash_type" => "type"
                         }
                       },
                       %{
                         "capacity" => "0x3691d6afc000",
                         "lock" => %{
                           "args" =>
                             "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8f245705db4fe72be953e4f9ee3808a1700a578341aa80a8b2349c236c4af64e5dd0c000000000000",
                           "code_hash" =>
                             "0x7f5a09b8bd0e85bcf2ccad96411ccba2f289748a1c16900b0635c2ed9126f288",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       },
                       %{
                         "capacity" => "0xf81ab5a00",
                         "lock" => %{
                           "args" =>
                             "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd805336bfc4817282542ede92aa9c8aff687d146480ccf012568fc8f4af205fc0bdd0c000000000000126a5078e98951de423a142fcd204240d4d4f1216a14e232356884cb054e32d067a7bfc639c348f7bfb833825304cfa79d7a02bc4fb6d7c2712b1400566b87630000004b4b00000010000000300000003100000079f90bb5e892d80dd213439eeab551120eb417678824f282b4ffb5f21bad2e1e011600000001890616016250e494f2da742496c8ec491546525f00",
                           "code_hash" =>
                             "0x06ae0706bb2d7997d66224741d3ec7c173dbb2854a6d2cf97088796b677269c6",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       },
                       %{
                         "capacity" => "0x48f18a0680",
                         "lock" => %{
                           "args" =>
                             "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8ad00000010000000300000003800000000000000000000000000000000000000000000000000000000000000000000000000000000000000750000001400000034000000690000007100000000000000000000000000000000000000000000000000000000000000000000003500000010000000300000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                           "code_hash" =>
                             "0x85ae4db0dd83f428a31deb342e4000af37ce2c9645d9e619df00096e3c50a2bb",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       },
                       %{
                         "capacity" => "0x2a1090ead",
                         "lock" => %{
                           "args" => "0xc267a8b93cdae15fb06325f11a72b1047bd4d33c",
                           "code_hash" =>
                             "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                           "hash_type" => "type"
                         },
                         "type" => nil
                       }
                     ],
                     "outputs_data" => [
                       "0xa0cf6037bfc238b179b74a30a9b12e15a4fbdd8881aebc8e5a66a8b5b5c95f0a4d4fc9d963d7ff0314515fd34b75b28a7259a220e66af197bcc7a375083ddb2a4d000000164eb074a40013ec2b568811358295fc39167e492e87ae2d70405bd1879136e0de0c000000000000000000000000000000000000000000000000000000000000000000000000000005336bfc4817282542ede92aa9c8aff687d146480ccf012568fc8f4af205fc0bc833aca780010000790c0000000000000001",
                       "0x",
                       "0x",
                       "0x",
                       "0x"
                     ],
                     "version" => "0x0",
                     "witnesses" => [
                       "0x55000000100000005500000055000000410000006411cb6a28f0a32f6eadaee52985aef242daa4220f7882d4936811af001ef5da3783ffeee0e6d24e3fcd3da2d6aaaae2efb4a8d852249400e987c3d14a3a06ef00",
                       "0x55000000100000005500000055000000410000006411cb6a28f0a32f6eadaee52985aef242daa4220f7882d4936811af001ef5da3783ffeee0e6d24e3fcd3da2d6aaaae2efb4a8d852249400e987c3d14a3a06ef00"
                     ]
                   }
                 ],
                 "uncles" => []
               },
               block_number: 5_305_363
             }
           ],
           errors: []
         }}
      end)

      GodwokenIndexer.Block.SyncL1BlockWorker.handle_info({:bind_deposit_work, 5_305_363}, [])
      assert WithdrawalHistory |> Repo.aggregate(:count) == 1
    end
  end
end
