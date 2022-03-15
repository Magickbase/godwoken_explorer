defmodule GodwokenExplorer.Graphql.Types.AccountUDT do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :web3_account_udt_querys do
    field :account_udt, :account_udt do
      arg(:input, :account_udt_input)
      resolve(&Resolvers.AccountUDT.account_udt/3)
    end

    field :account_udts, list_of(:account_udt) do
      arg(:input, list_of(:account_udt_input))
      resolve(&Resolvers.AccountUDT.account_udts/3)
    end
  end

  object :account_udt_querys do
    field :account_udts_by_contract_address, list_of(:account_udt) do
      arg(:input, :account_udt_contract_address_input)
      resolve(&Resolvers.AccountUDT.account_udts/3)
    end
  end

  object :account_udt do
    field :id, :integer
    field :balance, :decimal
    field :address_hash, :string
    field :token_contract_address_hash, :string
  end

  input_object :account_udt_input do
    field :address_hash, :string
    field :token_contract_address_hash, :string
  end

  input_object :account_udt_contract_address_input do
    field :token_contract_address_hash, :string
  end
end
