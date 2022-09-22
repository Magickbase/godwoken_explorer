defmodule GodwokenIndexer.Block.PendingTransactionWorkerTest do
  use GodwokenExplorer.DataCase

  import Mock

  alias GodwokenExplorer.{Transaction, Repo, Polyjuice}

  test "import pending transaction" do
    with_mocks([
      {GodwokenRPC, [],
       [
         fetch_pending_tx_hashes: fn ->
           {:ok, ["0xa312962527ae503c23dadc95fb007683d99a525006781ec6990b1671cc025800"]}
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
                }
              ]
            }}
         end
       ]}
    ]) do
      GodwokenIndexer.Block.PendingTransactionWorker.fetch_and_update()
      assert Transaction |> Repo.aggregate(:count) == 1

      pending_tx = Transaction |> limit(1) |> Repo.one()
      p = Polyjuice |> Repo.get_by(tx_hash: pending_tx.hash)

      assert pending_tx.hash |> to_string() ==
               "0xa312962527ae503c23dadc95fb007683d99a525006781ec6990b1671cc025800"

      assert p.native_transfer_address_hash |> to_string() ==
               "0xd1667cbf1cc60da94c1cf6c9cfb261e71b6047f7"
    end
  end
end
