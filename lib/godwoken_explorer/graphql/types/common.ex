defmodule GodwokenExplorer.Graphql.Types.Common do
  use Absinthe.Schema.Notation

  object :ecto_datetime do
    field :inserted_at, :datetime
    field :updated_at, :datetime
  end

  object :ecto_naive_datetime do
    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  object :paginate_metadata do
    field :after, :string
    field :before, :string
    field :limit, :integer
    field :total_count, :integer
    field :total_count_cap_exceeded, :boolean
  end

  input_object :paginate_input do
    @desc "Fetch the records before this cursor."
    field :before, :string
    @desc "Fetch the records after this cursor."
    field :after, :string

    @desc "Limits the number of records returned per page. Note that this number will be capped by maximum_limit=100. Defaults to 20."
    field :limit, :integer, default_value: 20
  end

  input_object :page_and_size_input do
    @desc """
    argument: the page of query result, the relations of postgres offset: offset = (page - 1) * page_size

    default: 1
    limit: > 0
    """
    field :page, :integer, default_value: 1

    @desc """
    argument: the page_size of query result, it's the same of postgres limit

    default: 20
    limit: > 0
    """
    field :page_size, :integer, default_value: 20
  end

  input_object :age_range_input do
    field :age_range_start, :datetime
    field :age_range_end, :datetime
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
