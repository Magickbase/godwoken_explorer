defmodule GodwokenExplorer.Graphql.Types.Common do
  use Absinthe.Schema.Notation
  # alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  input_object :page_and_size_input do
    field :page, :integer
    field :size, :integer
  end
end
