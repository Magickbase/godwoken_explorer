defmodule GodwokenExplorer.Factory do
  use ExMachina.Ecto, repo: GodwokenExplorer.Repo

  alias Decimal, as: D

  alias GodwokenExplorer.{
    Block,
    Transaction,
    Account,
    Repo,
    UDT
  }

  def block_factory do
    %Block{
      hash: "0x9e449451846827df40c9a8bcb2809256011afbbf394de676d52535c3ca32a518",
      parent_hash: "0xa04ecc2bb1bc634848535b60b3223c1cd5278aa93abb2c138687da8ffa9ffd48",
      number: 14,
      timestamp: ~U[2021-10-31 05:39:38.000000Z],
      status: :finalized,
      transaction_count: 1,
      gas_limit: D.new(12_500_000),
      gas_used: D.new(0),
      size: 156,
      logs_bloom:
        "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      layer1_block_number: 2_345_241,
      layer1_tx_hash: "0xae12080b62ec17acc092b341a6ca17da0708e7a6d77e8033c785ea48cdbdbeef"
    }
  end

  def meta_contract_factory do
    %Account{
      id: 0,
      nonce: 0,
      script_hash: "0x5c84fc6078725df72052cc858dffc6f352a069706c9023a82eeff3b2a1a9ccd1",
      registry_address: "0x5c84fc6078725df72052cc858dffc6f352a06970",
      type: :meta_contract
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
      nonce: sequence(:nonce, & &1, start_at: 0),
      to_account_id: 6,
      type: :sudt
    }
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end

  def ckb_udt_factory do
    %UDT{
      id: 1,
      name: "CKB",
      decimal: 8,
      script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      type: :bridge
    }
  end

  def ckb_account_factory do
    %{
      id: 1,
      type: :udt,
      registry_address: "0x9e9c54293c3211259de788e97a31b5b3a66cd535",
      script_hash: "0x9e9c54293c3211259de788e97a31b5b3a66cd53564f8d39dfabdc8e96cdf5ea4"
    }
  end
end
