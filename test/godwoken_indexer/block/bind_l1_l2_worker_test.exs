defmodule GodwokenIndexer.Block.BindL1L2WorkerTest do
  use GodwokenExplorer.DataCase

  import Mock

  setup do
    block = insert(:block, number: 10)
    %{block: block}
  end

  test "bind l1 l2 block successfully", %{block: block} do
    with_mocks([
      {GodwokenRPC, [],
       [
         fetch_l1_tip_block_number: fn ->
           {:ok, 5_293_290}
         end
       ]},
      {GodwokenRPC, [],
       [
         fetch_l1_txs_by_range: fn _ ->
           {:ok,
            %{
              "last_cursor" =>
                "0xa01e44736436b406f8e48a30dfbddcf044feb0c9eebfe63b0f81cb5bb727d848540186c7429247beba7ddd6e4361bcdfc0510b0b644131e2afb7e486375249a01802000000000050c4ea000000020000000001",
              "objects" => [
                %{
                  "block_number" => "0x50c4ea",
                  "io_index" => "0x0",
                  "io_type" => "input",
                  "tx_hash" =>
                    "0x5155c589fab7b6f88d3da93331e08eb4b59d2cecf40787d2ad74b7a2d48910f3",
                  "tx_index" => "0x2"
                },
                %{
                  "block_number" => "0x50c4ea",
                  "io_index" => "0x0",
                  "io_type" => "output",
                  "tx_hash" =>
                    "0x5155c589fab7b6f88d3da93331e08eb4b59d2cecf40787d2ad74b7a2d48910f3",
                  "tx_index" => "0x2"
                }
              ]
            }}
         end
       ]},
      {GodwokenRPC, [],
       [
         fetch_l1_tx: fn _tx_hash ->
           {:ok,
            %{
              "cycles" => nil,
              "transaction" => %{
                "cell_deps" => [
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
                        "0xcd52d714ddea04d2917892f16d47cbd0bbbb7d9ba281233ec4021f79fc34bccc"
                    }
                  },
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
                        "0x053fdb4ed3181eab3a3a5f05693b53a8cdec0a24569e16369f444bac48be7de9"
                    }
                  }
                ],
                "hash" => "0x5155c589fab7b6f88d3da93331e08eb4b59d2cecf40787d2ad74b7a2d48910f3",
                "header_deps" => [],
                "inputs" => [
                  %{
                    "previous_output" => %{
                      "index" => "0x0",
                      "tx_hash" =>
                        "0x399a5a2ad654be4e96148933511fb17a5f0e3ed9c88b1b14edca14211f4d94ad"
                    },
                    "since" => "0x400000006277471b"
                  },
                  %{
                    "previous_output" => %{
                      "index" => "0x2",
                      "tx_hash" =>
                        "0x399a5a2ad654be4e96148933511fb17a5f0e3ed9c88b1b14edca14211f4d94ad"
                    },
                    "since" => "0x0"
                  },
                  %{
                    "previous_output" => %{
                      "index" => "0x3",
                      "tx_hash" =>
                        "0x399a5a2ad654be4e96148933511fb17a5f0e3ed9c88b1b14edca14211f4d94ad"
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
                        "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8f245705db4fe72be953e4f9ee3808a1700a578341aa80a8b2349c236c4af64e50a00000000000000",
                      "code_hash" =>
                        "0x7f5a09b8bd0e85bcf2ccad96411ccba2f289748a1c16900b0635c2ed9126f288",
                      "hash_type" => "type"
                    },
                    "type" => nil
                  },
                  %{
                    "capacity" => "0x2a187a31b",
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
                  "0xa0cf6037bfc238b179b74a30a9b12e15a4fbdd8881aebc8e5a66a8b5b5c95f0adfbca3909e14aaa4c491b27a896f6ec8fdfd3b819c948b56eb5a9b22f9e21ca907000000d1e43404a47819ca8cd38ec252b484721c97c670c4e1c673542ec290ccf3bdb70b00000000000000000000000000000000000000000000000000000000000000000000000000000036141cb6d902889f13e889b3625d7acc33b23a23dc499c4a4f09ff463727fe0e7fbeeda18001000000000000000000000001",
                  "0x",
                  "0x"
                ],
                "version" => "0x0",
                "witnesses" => [
                  "0x520200001000000069000000690000005500000055000000100000005500000055000000410000008a43ef4a3e004ae871d400ec7b50a5ac79187230d813959982830861bb2c7ef153ea144e1b6aa70e4fbfd5f24d2e280e6a5707bd32ea8398c1a560b007e1c7b501e501000000000000e101000010000000d9010000dd010000c90100001c0000006c010000700100007401000078010000c5010000500100002c000000340000005400000074000000940000009c000000c0000000e4000000e80000000c0100000a000000000000001c0000000200000014000000715ab282b873b79a7be8b0e8c13c4e8966a520400378e097e9bebfea400e8928654737943761869fbcd8edd2c5e7e0254efabef2f245705db4fe72be953e4f9ee3808a1700a578341aa80a8b2349c236c4af64e57fbeeda180010000dfbca3909e14aaa4c491b27a896f6ec8fdfd3b819c948b56eb5a9b22f9e21ca907000000dfbca3909e14aaa4c491b27a896f6ec8fdfd3b819c948b56eb5a9b22f9e21ca907000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004824881c0692cad76e01cfcb7cea3c6f1d07b2406894a11ec2b8bcd5b39146a9000000000000000004000000490000004c4f01507441c72ef9920c456925402c6f57830b2afe84c68d3e31bc2ee190c64454d1bc4f0150d1a5696df2429f826264959507a9082a36db4a26e5c5965a98d7ae9bab1495284ffc040000000000000000000000",
                  "0x55000000100000005500000055000000410000004f18ba7b0f8c8db75ef29f4fc7e9dee4ca74fe44b26a1308a5842723991085b842920d661e9040153399d9567902d49e1487781c1fad07a1f092ba0dd2b27d6400",
                  "0x55000000100000005500000055000000410000004f18ba7b0f8c8db75ef29f4fc7e9dee4ca74fe44b26a1308a5842723991085b842920d661e9040153399d9567902d49e1487781c1fad07a1f092ba0dd2b27d6400"
                ]
              },
              "tx_status" => %{
                "block_hash" =>
                  "0x1e608d6f8def6177553800d40c3ab7539ec7042b47784b08946611c33f01a903",
                "reason" => nil,
                "status" => "committed"
              }
            }}
         end
       ]}
    ]) do
      GodwokenIndexer.Block.BindL1L2Worker.handle_info({:bind_l1_work, 10}, [])

      assert Repo.reload(block).layer1_block_number == 5_293_290
    end
  end

  test "when greater than l1 tip block_number", %{block: block} do
    with_mocks([
      {GodwokenRPC, [],
       [
         fetch_l1_tip_block_number: fn ->
           {:ok, 5_293_290}
         end
       ]}
    ]) do
      GodwokenIndexer.Block.BindL1L2Worker.handle_info({:bind_l1_work, 5_293_291}, [])

      assert Repo.reload(block).layer1_block_number == nil
    end
  end

  test "when no output", %{block: block} do
    with_mocks([
      {GodwokenRPC, [],
       [
         fetch_l1_tip_block_number: fn ->
           {:ok, 5_293_290}
         end
       ]},
      {GodwokenRPC, [],
       [
         fetch_l1_txs_by_range: fn _ ->
           {:ok,
            %{
              "last_cursor" =>
                "0xa01e44736436b406f8e48a30dfbddcf044feb0c9eebfe63b0f81cb5bb727d848540186c7429247beba7ddd6e4361bcdfc0510b0b644131e2afb7e486375249a01802000000000050c4ea000000020000000001",
              "objects" => [
                %{
                  "block_number" => "0x50c4ea",
                  "io_index" => "0x0",
                  "io_type" => "input",
                  "tx_hash" =>
                    "0x5155c589fab7b6f88d3da93331e08eb4b59d2cecf40787d2ad74b7a2d48910f3",
                  "tx_index" => "0x2"
                }
              ]
            }}
         end
       ]}
    ]) do
      GodwokenIndexer.Block.BindL1L2Worker.handle_info({:bind_l1_work, 5_293_250}, [])

      assert Repo.reload(block).layer1_block_number == nil
    end
  end

  test "when rpc fetch error", %{block: block} do
    with_mocks([
      {GodwokenRPC, [],
       [
         fetch_l1_tip_block_number: fn ->
           {:ok, 5_293_290}
         end
       ]},
      {GodwokenRPC, [],
       [
         fetch_l1_txs_by_range: fn _ ->
           {:error, :network_error}
         end
       ]}
    ]) do
      GodwokenIndexer.Block.BindL1L2Worker.handle_info({:bind_l1_work, 5_293_260}, [])

      assert Repo.reload(block).layer1_block_number == nil
    end
  end

  test "test start_link", %{block: block} do
    with_mocks([
      {GodwokenRPC, [],
       [
         fetch_l1_tip_block_number: fn ->
           {:ok, 100}
         end
       ]}
    ]) do
      start_supervised(GodwokenIndexer.Block.BindL1L2Worker)

      assert Repo.reload(block).layer1_block_number == nil
    end
  end
end
