defmodule GodwokenExplorer.Graphql.Types.Block do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :block_querys do
    field :latest_10_blocks, list_of(:block) do
      resolve(&Resolvers.Block.latest_10_blocks/3)
    end

    field :block, :block do
      arg(:input, :block_input)
      resolve(&Resolvers.Block.block/3)
    end

    field :blocks, list_of(:block) do
      arg(:input, :page_and_size_input)
      resolve(&Resolvers.Block.blocks/3)
    end
  end

  object :block_mutations do
  end

  object :block do
    field :hash, :string
    field :number, :integer
    field :parent_hash, :string
    field :timestamp, :datetime
    field :status, :block_status
    field :aggregator_id, :integer
    field :transaction_count, :integer
    field :layer1_tx_hash, :string
    field :layer1_block_number, :integer
    field :size, :integer
    field :gas_limit, :decimal
    field :gas_used, :decimal
    field :logs_bloom, :string
    field :difficulty, :decimal
    field :total_difficulty, :decimal
    field :nonce, :string
    field :sha3_uncles, :string
    field :state_root, :string
    field :extra_data, :string

    field :account, :account do
      resolve(&Resolvers.Block.account/3)
    end

    field :transactions, list_of(:transaction) do
      resolve(&Resolvers.Block.transactions/3)
    end
  end

  enum :block_status do
    value(:committed)
    value(:finalized)
  end

  input_object :block_input do
    field :hash, :string
    field :number, :integer
  end
end
