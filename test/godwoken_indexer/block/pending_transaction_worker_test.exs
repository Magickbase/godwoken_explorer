defmodule GodwokenIndexer.Block.PendingTransactionWorkerTest do
  use GodwokenExplorer.DataCase

  import Mock

  alias GodwokenExplorer.{Transaction, Repo, Polyjuice, PolyjuiceCreator}

  test "import pending transaction" do
    with_mocks([
      {GodwokenRPC, [],
       [
         fetch_pending_tx_hashes: fn ->
           {:ok,
            [
              "0xa312962527ae503c23dadc95fb007683d99a525006781ec6990b1671cc025800",
              "0xd324ee7920336e5ca75de7d73dd85219434e3aa0ff1bd0cfea459ef837773318",
              "0xd82aec9b23649abad4d302da76f1dd20729525558c821f885cc801bc4c8fc2d4"
            ]}
         end
       ]},
      {GodwokenRPC, [],
       [
         fetch_pending_transactions: fn _tx_hashes ->
           {:ok,
            %{
              errors: [],
              params_list: [
                %{
                  "status" => "pending",
                  "transaction" => %{
                    "hash" =>
                      "0xa312962527ae503c23dadc95fb007683d99a525006781ec6990b1671cc025800",
                    "raw" => %{
                      "args" =>
                        "0xffffff504f4c590068bf00000000000000a007c2da5100000000000000000000000064a7b3b6e00d000000000000000000000000d1667cbf1cc60da94c1cf6c9cfb261e71b6047f7",
                      "chain_id" => "0x116e9",
                      "from_id" => "0xef60",
                      "nonce" => "0x0",
                      "to_id" => "0x4"
                    },
                    "signature" =>
                      "0x6fda1ebec3f5a5fc0570eaf37c2ecb64412b2babe1c393ea309f5ebf32b371225a3b1390f19fe9f81757d2bd4588f493317c49e04b7c655c528048e733c5411600"
                  }
                },
                %{
                  "status" => "pending",
                  "transaction" => %{
                    "hash" =>
                      "0xd324ee7920336e5ca75de7d73dd85219434e3aa0ff1bd0cfea459ef837773318",
                    "raw" => %{
                      "args" =>
                        "0x01000000910000000c0000007d00000071000000080000006900000010000000300000003100000007521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec00134000000702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8e009efc93ec27da29d82aad36fc6231b4a4e96270200000000000000000000000000000000000000",
                      "chain_id" => "0x116e9",
                      "from_id" => "0x3",
                      "nonce" => "0x0",
                      "to_id" => "0x0"
                    },
                    "signature" =>
                      "0x6fda1ebec3f5a5fc0570eaf37c2ecb64412b2babe1c393ea309f5ebf32b371225a3b1390f19fe9f81757d2bd4588f493317c49e04b7c655c528048e733c5411600"
                  }
                },
                %{
                  "status" => "pending",
                  "transaction" => %{
                    "hash" =>
                      "0xd82aec9b23649abad4d302da76f1dd20729525558c821f885cc801bc4c8fc2d4",
                    "raw" => %{
                      "args" =>
                        "0x0200000062af4d27af4e73286d60f8208638b2f9db1a0358f6108d3a701892711d85e1670200000001000000000000000000000000000000",
                      "chain_id" => "0x116e9",
                      "from_id" => "0xf2",
                      "nonce" => "0xa",
                      "to_id" => "0x2"
                    },
                    "signature" =>
                      "0x6fda1ebec3f5a5fc0570eaf37c2ecb64412b2babe1c393ea309f5ebf32b371225a3b1390f19fe9f81757d2bd4588f493317c49e04b7c655c528048e733c5411600"
                  }
                }
              ]
            }}
         end
       ]}
    ]) do
      GodwokenIndexer.Block.PendingTransactionWorker.handle_info(:fetch, [])

      assert Transaction |> Repo.aggregate(:count) == 3
      assert Polyjuice |> Repo.aggregate(:count) == 1
      assert PolyjuiceCreator |> Repo.aggregate(:count) == 1

      p =
        Polyjuice
        |> Repo.get_by(
          tx_hash: "0xa312962527ae503c23dadc95fb007683d99a525006781ec6990b1671cc025800"
        )

      assert p.input_size == 0
      assert p.input |> to_string() == "0x"

      assert p.native_transfer_address_hash |> to_string() ==
               "0xd1667cbf1cc60da94c1cf6c9cfb261e71b6047f7"
    end
  end

  test "when rpc connect failed" do
    with_mocks([
      {GodwokenRPC, [],
       [
         fetch_pending_tx_hashes: fn ->
           {:error, :node_error}
         end
       ]},
      {GodwokenRPC, [],
       [
         fetch_pending_transactions: fn _tx_hashes ->
           {:error, :node_error}
         end
       ]}
    ]) do
      GodwokenIndexer.Block.PendingTransactionWorker.fetch_and_update()
      assert Transaction |> Repo.aggregate(:count) == 0
    end
  end

  test "fetch mempool transactions" do
    with_mock GodwokenRPC,
      fetch_mempool_transaction: fn _eth_hash ->
        {:ok,
         %{
           "status" => "committed",
           "transaction" => %{
             "hash" => "0x1cfee93deed308e1bba6bf79821737ac66e537474932c137898243b04987554a",
             "raw" => %{
               "args" =>
                 "0xffffff504f4c590038c7000000000000fedd439f070000000000000000000000000000000000000000000000000000000000000002fe5abfc9054c9e23b47c7743ee6f55b35e8470",
               "chain_id" => "0x116e9",
               "from_id" => "0xa041",
               "nonce" => "0x32",
               "to_id" => "0x4"
             },
             "signature" =>
               "0x98ddd37908d6022a77bdba8d4739ace9599f1c126704cf68add6b57dcd737c596fab8f13d31a2bfad94ebc38c46304e708d02f7bc0cdcc3f5bc1b42fff38d62201"
           }
         }}
      end do
      GodwokenIndexer.Block.PendingTransactionWorker.parse_and_import(
        "0x019d19911a44651bde39ba6d44a3f0a56cfdccefdf4c2e953ed8ef04e503b0dd"
      )

      assert Repo.aggregate(Transaction, :count) == 1
      assert Repo.aggregate(Polyjuice, :count) == 1
    end
  end
end
