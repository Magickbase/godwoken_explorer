defmodule GodwokenExplorer.Graphql.Types.TokenTransfer do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :token_transfer_querys do
    field :token_transfer, :token_transfer do
      arg(:input, :token_transfer_hash_input)
      resolve(&Resolvers.TokenTransfer.token_transfer/3)
    end

    field :token_transfers, list_of(:token_transfer) do
      arg(:input, :token_transfer_input)
      resolve(&Resolvers.TokenTransfer.token_transfers/3)
    end
  end

  object :token_transfer do
    import_fields :ecto_datetime
    field :transaction_hash, :string
    field :amount, :decimal
    field :block_number, :integer
    field :block_hash, :string
    field :log_index, :integer
    field :token_id, :decimal
    field :from_address_hash, :string
    field :to_address_hash, :string
    field :token_contract_address_hash, :string


    field :polyjuice, :polyjuice do
      resolve(&Resolvers.TokenTransfer.polyjuice/3)
    end

    field :from_account, :account do
      resolve(&Resolvers.TokenTransfer.from_account/3)
    end

    field :to_account, :account do
      resolve(&Resolvers.TokenTransfer.to_account/3)
    end

    field :udt, :udt do
      resolve(&Resolvers.TokenTransfer.udt/3)
    end

    field :block, :block do
      resolve(&Resolvers.TokenTransfer.block/3)
    end

    field :transaction, :block do
      resolve(&Resolvers.TokenTransfer.transaction/3)
    end
  end

  input_object :token_transfer_input do
    field(:from_address_hash, :string)
    field(:to_address_hash, :string)
    field(:token_contract_address_hash, :string)
    import_fields(:page_and_size_input)
    import_fields(:block_range_input)
  end

  input_object :token_transfer_hash_input do
    field :transaction_hash, :string
  end
end
