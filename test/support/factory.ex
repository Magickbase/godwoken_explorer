defmodule GodwokenExplorer.Factory do
  use ExMachina.Ecto, repo: Explorer.Repo

  alias GodwokenExplorer.Block

  def block_factory do
    %Block{
      aggregator_id: 0,
      average_gas_price: nil,
      hash: "0x4ab47c3a847ede67fdad6357e7bf0a017fdb1be3e437a675a742e268af39bc3d",
      layer1_block_number: 3312,
      layer1_tx_hash: "0x9d551b30032f9c4f30a931e431cc7bf91afc0d912880b90371f0a668c7af9489",
      number: 100,
      parent_hash: "0xa3c7622d9016ce604fdcda94885923fcb576927667bfe915125d190db4b2b1d2",
      size: nil,
      status: :committed,
      timestamp: ~U[2021-02-28 13:10:49.000000Z],
      transaction_count: 0,
      tx_fees: nil
   }
  end
end
