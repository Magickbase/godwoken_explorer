defmodule GodwokenExplorer.Graphql.Types.Log do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :web3_log_querys do
    field :logs, list_of(:log) do
      arg(:input, :log_input)
      resolve(&Resolvers.Log.logs/3)
    end
  end

  object :log do
    field :transaction_hash, :string
    field :data, :string
    field :first_topic, :string
    field :second_topic, :string
    field :third_topic, :string
    field :fourth_topic, :string
    field :index, :integer
    field :block_number, :integer
    field :address_hash, :string
    field :block_hash, :string
  end

  input_object :log_input do
    field :first_topic, :string
    field :second_topic, :string
    field :third_topic, :string
    field :fourth_topic, :string
    import_fields(:page_and_size_input)
    import_fields(:block_range_input)
  end
end
