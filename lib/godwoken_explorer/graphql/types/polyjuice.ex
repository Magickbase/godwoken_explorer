defmodule GodwokenExplorer.Graphql.Types.Polyjuice do
  use Absinthe.Schema.Notation
  # alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :polyjuice do
    field :id, :integer
    field :is_create, :boolean
    field :gas_limit, :bigint
    field :gas_price, :bigint
    field :value, :bigint
    field :input_size, :integer
    field :input, :chain_data
    field :tx_hash, :hash_full
    field :gas_used, :bigint
    field :transaction_index, :integer
    field :created_contract_address_hash, :hash_address
    field :status, :polyjuice_status
  end

  object :polyjuice_creator do
    field :id, :integer
    field :code_hash, :string
    field :hash_type, :string
    field :script_args, :string
    field :tx_hash, :hash_full
    field :fee_amount, :bigint
    field :fee_udt_id, :integer
  end

  enum :polyjuice_status do
    value(:succeed)
    value(:failed)
  end
end
