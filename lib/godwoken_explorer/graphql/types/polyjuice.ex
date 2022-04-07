defmodule GodwokenExplorer.Graphql.Types.Polyjuice do
  use Absinthe.Schema.Notation
  # alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :polyjuice do
    field :id, :integer
    field :is_create, :boolean
    field :gas_limit, :integer
    field :gas_price, :decimal
    field :value, :decimal
    field :input_size, :integer
    field :input, :string
    field :tx_hash, :string
    field :gas_used, :integer
    field :status, :polyjuice_status
  end

  object :polyjuice_creator do
    field :id, :integer
    field :code_hash, :string
    field :hash_type, :string
    field :script_args, :string
    field :tx_hash, :string
    field :fee_amount, :decimal
    field :fee_udt_id, :integer
  end

  enum :polyjuice_status do
    value :succeed
    value :failed
  end
end
