defmodule GodwokenExplorer.Graphql.Types.Common do
  use Absinthe.Schema.Notation

  object :ecto_datetime do
    field :inserted_at, :datetime
    field :updated_at, :datetime
  end

  input_object :page_and_size_input do
    @desc """
    argument: the page of query result, the relations of postgres offset: offset = (page - 1) * page_size

    default: 1
    """
    field :page, :integer, default_value: 1

    @desc """
    argument: the page_size of query result, it's the same of postgres limit

    default: 20
    """
    field :page_size, :integer, default_value: 20
  end

  input_object :block_range_input do
    @desc """
    argument: the start of block number(inclusive) for search query
    """
    field :start_block_number, :integer

    @desc """
    argument: the end of block number(inclusive) for search query
    """
    field :end_block_number, :integer
  end

  input_object :sort_type_input do
    @desc """
    argument: the sort of type by custom condition

    default: desc
    """
    field :sort_type, :sort_type, default_value: :desc
  end

  enum :sort_type do
    value(:asc)
    value(:desc)
  end
end
