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

    field :transactions_contract_eth_address, list_of(:transaction) do
      arg(:input, :transaction_contract_eth_address_input)
      resolve(&Resolvers.Transaction.transactions/3)
    end

    field :transactions_eth_address, list_of(:transaction) do
      arg(:input, :transaction_eth_address_input)
      resolve(&Resolvers.Transaction.transactions/3)
    end

    field :transactions_contract_address, list_of(:transaction) do
      arg(:input, :transaction_contract_address_input)
      resolve(&Resolvers.Transaction.transactions/3)
    end

    field :transactions_block_hash, list_of(:transaction) do
      arg(:input, :transaction_block_hash_input)
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

    field :account, :account do
      resolve(&Resolvers.Transaction.account/3)
    end

    field :udt, :udt do
      resolve(&Resolvers.Transaction.udt/3)
    end

    field :block, :block do
      resolve(&Resolvers.Transaction.block/3)
    end

    field :smart_contract, :smart_contract do
      resolve(&Resolvers.Transaction.smart_contract/3)
    end
  end

  enum :transaction_type do
    value(:sudt)
    value(:polyjuice_creator)
    value(:polyjuice)
  end

  input_object :transaction_contract_eth_address_input do
    field :eth_address, :string
    field :contract_address, :string
    import_fields(:page_and_size_input)
  end

  input_object :transaction_eth_address_input do
    field :eth_address, :string
    import_fields(:page_and_size_input)
  end

  input_object :transaction_contract_address_input do
    field :contract_address, :string
    import_fields(:page_and_size_input)
  end

  input_object :transaction_block_hash_input do
    field :block_hash, :string
    import_fields(:page_and_size_input)
  end

  input_object :transaction_hash_input do
    field :hash, :string
  end
end
