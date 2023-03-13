defmodule GodwokenIndexer.Block.GlobalStateWorkerTest do
  use GodwokenExplorer.DataCase

  import Mock

  setup do
    block = insert(:block)
    meta = insert(:meta_contract)
    withdrawal_history = insert(:withdrawal_history)
    %{block: block, meta: meta, withdrawal_history: withdrawal_history}
  end

  test "fetch global state", %{block: block, meta: meta, withdrawal_history: withdrawal_history} do
    with_mock GodwokenRPC,
      fetch_cells: fn _, "type" ->
        {:ok,
         %{
           "last_cursor" =>
             "0x601e44736436b406f8e48a30dfbddcf044feb0c9eebfe63b0f81cb5bb727d848540186c7429247beba7ddd6e4361bcdfc0510b0b644131e2afb7e486375249a01802000000000082b4c90000000400000000",
           "objects" => [
             %{
               "block_number" => "0x82b4c9",
               "out_point" => %{
                 "index" => "0x0",
                 "tx_hash" => "0x95f2acf72ce2918c46780011d74160b833d923d6cfa3809254e2bebe428f6226"
               },
               "output" => %{
                 "capacity" => "0x7676d7e00",
                 "lock" => %{
                   "args" => "0x00c267a8b93cdae15fb06325f11a72b1047bd4d33c00",
                   "code_hash" =>
                     "0x79f90bb5e892d80dd213439eeab551120eb417678824f282b4ffb5f21bad2e1e",
                   "hash_type" => "type"
                 },
                 "type" => %{
                   "args" => "0x86c7429247beba7ddd6e4361bcdfc0510b0b644131e2afb7e486375249a01802",
                   "code_hash" =>
                     "0x1e44736436b406f8e48a30dfbddcf044feb0c9eebfe63b0f81cb5bb727d84854",
                   "hash_type" => "type"
                 }
               },
               "output_data" =>
                 "0xa0cf6037bfc238b179b74a30a9b12e15a4fbdd8881aebc8e5a66a8b5b5c95f0acb1f92d8fb81a42813755569f88e1340b0be2d04ea2f728c03f209b17e3801f2859e0100e1555ac08f3482f605c945d2569ad27a001f4d3fb3c1df8e6ba40165346ed6d215121f00000000000000000000000000000000000000000000000000000000000000000000000000f9dca827960de0f816c4a195d5173ba29f793d95085c49bd8aeb953b9990449abf2950bc86010000b0111f00000000000001",
               "tx_index" => "0x4"
             }
           ]
         }}
      end do
      GodwokenIndexer.Block.GlobalStateWorker.handle_info(:finalized_work, [])

      assert Repo.reload(block).status == :finalized
      assert Repo.reload(meta).script["status"] == "running"
      assert Repo.reload(withdrawal_history).state == :available
    end
  end
end
