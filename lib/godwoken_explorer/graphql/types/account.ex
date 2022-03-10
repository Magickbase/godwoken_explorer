defmodule GodwokenExplorer.Graphql.Types.Account do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :account_querys do
    field :account, :account do
      arg(:input, :account_input)
      resolve(&Resolvers.Account.account/3)
    end
  end

  object :account_mutations do
  end

  object :account do
    field :id, :integer
    field :eth_address, :string
    field :script_hash, :string
    field :short_address, :string
    field :script, :json
    field :nonce, :integer
    field :type, :account_type
  end

  enum :account_type do
    value(:meta_contract)
    value(:udt)
    value(:user)
    value(:polyjuice_root)
    value(:polyjuice_contract)
  end

  input_object :account_input do
    field :eth_address_or_short_address, :string
  end
end
