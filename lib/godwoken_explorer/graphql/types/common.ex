defmodule GodwokenExplorer.Graphql.Types.Common do
  use Absinthe.Schema.Notation
  # alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  input_object :page_and_size_input do
    field :page, :integer
    field :page_size, :integer
  end

  input_object :block_range_input do
    field :from_block_number, :integer
    field :to_block_number, :integer
  end

  enum :sort_type do
    value :asc
    value :desc
  end
end
