defmodule GodwokenExplorer.Graphql.Types.Common do
  use Absinthe.Schema.Notation
  # alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :ecto_datetime do
    field :inserted_at, :datetime
    field :updated_at, :datetime
  end

  input_object :page_and_size_input do
    field :page, :integer, default_value: 1
    field :page_size, :integer, default_value: 100
  end

  input_object :block_range_input do
    field :start_block_number, :integer
    field :end_block_number, :integer
  end

  enum :sort_type do
    value :asc
    value :desc
  end
end
