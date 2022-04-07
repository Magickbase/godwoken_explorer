defmodule GodwokenExplorer.Graphql.Types.SmartContract do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :smart_contract_querys do
    field :smart_contract, :smart_contract do
      arg(:input, :smart_contract_input)
      resolve(&Resolvers.SmartContract.smart_contract/3)
    end

    field :smart_contracts, list_of(:smart_contract) do
      arg(:input, :page_and_size_input)
      resolve(&Resolvers.SmartContract.smart_contracts/3)
    end
  end

  object :smart_contract do
    field :id, :integer
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

  input_object :smart_contract_input do
    field :contract_address, :string
  end
end
