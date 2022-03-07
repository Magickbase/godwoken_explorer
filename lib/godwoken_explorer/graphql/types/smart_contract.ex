defmodule GodwokenExplorer.Graphql.Types.SmartContract do
  use Absinthe.Schema.Notation
  # alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :smart_contract do
    field :abi, list_of(:json)
    field :contract_source_code, :string
    field :name, :string
    field :account_id, :string
    field :constructor_arguments, :string
    field :deployment_tx_hash, :string
    field :compiler_version, :string
    field :compiler_file_format, :string
    field :other_info, :string
  end
end
