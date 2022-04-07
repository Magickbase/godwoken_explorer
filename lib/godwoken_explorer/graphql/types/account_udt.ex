defmodule GodwokenExplorer.Graphql.Types.AccountUDT do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :account_udt_querys do
    field :account_udts, list_of(:account_udt) do
      arg(:input, :account_udts_input)
      resolve(&Resolvers.AccountUDT.account_udts/3)
    end

    field :account_ckbs, list_of(:account_ckb) do
      arg(:input, :account_ckbs_input)
      resolve(&Resolvers.AccountUDT.account_ckbs/3)
    end

    field :account_udts_by_contract_address, list_of(:account_udt) do
      arg(:input, :account_udt_contract_address_input)
      resolve(&Resolvers.AccountUDT.account_udts_by_contract_address/3)
    end
  end

  object :account_ckb do
    field :address_hash, :string
    field :balance, :decimal
  end

  object :account_udt do
    field :id, :integer
    field :balance, :decimal
    field :address_hash, :string
    field :inputs, :string

    field :udt, :udt do
      resolve(&Resolvers.AccountUDT.udt/3)
    end

    field :account, :account do
      resolve(&Resolvers.AccountUDT.account/3)
    end
  end

  input_object :account_ckbs_input do
    field :address_hashes, list_of(:string), default_value: []
  end

  input_object :account_udts_input do
    field :address_hashes, list_of(:string), default_value: []
    field :token_contract_address_hash, :string, default_value: ""
  end

  input_object :account_udt_contract_address_input do
    field :token_contract_address_hash, :string, default_value: ""
  end
end
