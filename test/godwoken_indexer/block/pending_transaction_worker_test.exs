defmodule GodwokenIndexer.Block.PendingTransactionWorkerTest do
  use GodwokenExplorer.DataCase

  import Mock

  alias GodwokenExplorer.{Transaction, Repo}

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
                        "0xffffff504f4c590371dc03000000000000a007c2da5100000000000000000000000000000000000000000000000000005a020000608060405234801561001057600080fd5b50600260008190555030600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506002600a90806001815401808255809150506001900390600052602060002001600090919091909150556002606490806001815401808255809150506001900390600052602060002001600090919091909150556009600360006001815260200190815260200160002081905550600a600360006002815260200190815260200160002081905550610169806100f16000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c80635dab24201461003b5780638381f58a14610059575b600080fd5b610043610077565b60405161005091906100c1565b60405180910390f35b61006161009d565b60405161006e91906100dc565b60405180910390f35b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60005481565b6100ac816100f7565b82525050565b6100bb81610129565b82525050565b60006020820190506100d660008301846100a3565b92915050565b60006020820190506100f160008301846100b2565b92915050565b600061010282610109565b9050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600081905091905056fea2646970667358221220a9aef5f32df8dff6a2cb0140ee9c2b61e738c1feb0228beb74d7752170ae369164736f6c63430008060033",
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

      assert pending_tx.hash |> to_string() ==
               "0xa312962527ae503c23dadc95fb007683d99a525006781ec6990b1671cc025800"
    end
  end
end
