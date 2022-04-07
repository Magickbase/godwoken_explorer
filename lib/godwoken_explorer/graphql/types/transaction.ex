defmodule GodwokenExplorer.Graphql.Types.Transaction do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :transaction_querys do
    field :latest_10_transactions, list_of(:transaction) do
      resolve(&Resolvers.Transaction.latest_10_transactions/3)
    end

    field :transaction, :transaction do
      arg(:input, :transaction_hash_input)
      resolve(&Resolvers.Transaction.transaction/3)
    end

    field :transactions, list_of(:transaction) do
      arg(:input, :transaction_input)
      resolve(&Resolvers.Transaction.transactions/3)
    end
  end

  object :transaction_mutations do
  end

  object :transaction do
    field :hash, :string
    field :args, :string
    field :from_account_id, :integer
    field :nonce, :integer
    field :to_account_id, :integer
    field :type, :transaction_type
    field :block_number, :integer
    field :block_hash, :string

    field :polyjuice, :polyjuice do
      resolve(&Resolvers.Transaction.polyjuice/3)
    end

    field :polyjuice_creator, :polyjuice_creator do
      resolve(&Resolvers.Transaction.polyjuice_creator/3)
    end

    field :from_account, :account do
      resolve(&Resolvers.Transaction.from_account/3)
    end

    field :to_account, :account do
      resolve(&Resolvers.Transaction.to_account/3)
    end

    field :block, :block do
      resolve(&Resolvers.Transaction.block/3)
    end
  end

  enum :transaction_type do
    value(:polyjuice_creator)
    value(:polyjuice)
  end

  input_object :transaction_hash_input do
    field :transaction_hash, :string
  end

  input_object :transaction_input do
    field :address, :string
    field :sort, :sort_type
    import_fields(:page_and_size_input)
    import_fields(:block_range_input)
  end
end
