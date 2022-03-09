defmodule GodwokenExplorer.Graphql.Types.Search do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :search_querys do
    field :search, :search do
      arg(:input, :search_input)
      resolve(&Resolvers.Search.search/3)
    end
  end

  object :search do
    field :type, :search_type
    field :id, :string
  end

  enum :search_type do
    value(:account)
    value(:transaction)
    value(:block)
    value(:udt)
  end

  input_object :search_input do
    field :keyword, :string
  end
end
