defmodule GodwokenExplorer.Factory do
  use ExMachina.Ecto, repo: GodwokenExplorer.Repo

  alias GodwokenExplorer.{
    Block,
    Transaction
  }

  def block_factory do
    %Block{
      aggregator_id: 0,
      hash:
        sequence(:hash, &"0x#{&1}47c3a847ede67fdad6357e7bf0a017fdb1be3e437a675a742e268af39bc3d",
          start_at: 100
        ),
      layer1_block_number: sequence(:layer1_block_number, & &1, start_at: 3100),
      layer1_tx_hash: "0x9d551b30032f9c4f30a931e431cc7bf91afc0d912880b90371f0a668c7af9489",
      number: sequence(:number, & &1, start_at: 100),
      parent_hash: "0xa3c7622d9016ce604fdcda94885923fcb576927667bfe915125d190db4b2b1d2",
      size: nil,
      status: :committed,
      timestamp:
        sequence(
          :timestamp,
          &"#{NaiveDateTime.utc_now() |> DateTime.from_naive!("Etc/UTC") |> DateTime.add(&1)}",
          start_at: 60
        ),
      transaction_count: 1,
      transactions: build_list(1, :transaction)
    }
  end

  def transaction_factory do
    %Transaction{
      args: "0x01000000060000001600000000000000000000000000000001000000000000000000000000000000",
      from_account_id: 2,
      hash:
        sequence(:hash, &"0x#{&1}b6c0a6f68c929453197ca43b06b4735e4c04b105b9418954aae9240bfa7330",
          start_at: 100
        ),
      block_number: sequence(:block_number, & &1, start_at: 100),
      nonce: sequence(:nonce, &(&1), start_at: 0),
      to_account_id: 6,
      type: :sudt
    }
  end
end
