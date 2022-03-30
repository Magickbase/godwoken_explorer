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
    import_fields :ecto_datetime
    field :id, :integer
    field :eth_address, :string
    field :script_hash, :string
    field :short_address, :string
    field :script, :json
    field :nonce, :integer
    field :type, :account_type

    field :account_udts, list_of(:account_udt) do
      resolve(&Resolvers.Account.account_udts/3)
    end

    field :smart_contract, :smart_contract do
      resolve(&Resolvers.Account.smart_contract/3)
    end
  end

  enum :account_type do
    value(:meta_contract)
    value(:udt)
    value(:user)
    value(:polyjuice_root)
    value(:polyjuice_contract)
  end

  input_object :account_input do
    field :address, :string
  end
end
