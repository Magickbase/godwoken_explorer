defmodule GodwokenExplorer.Graphql.Types.SmartContract do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.Downcase, as: MDowncase

  object :smart_contract_querys do
    @desc """
    function: get smart contract by address

    request-example:
    query {
      smart_contract(input: {contract_address: "0x21c814bf216ec7b988d872c56bf948d9cc1638a2"}) {
        name
        account_id
        account {
          eth_address
        }
      }
    }

    result-example:
    {
      "data": {
        "smart_contract": {
          "account": {
            "eth_address": "0x21c814bf216ec7b988d872c56bf948d9cc1638a2"
          },
          "account_id": "3014",
          "name": "YOKAI"
        }
      }
    }
    """
    field :smart_contract, :smart_contract do
      arg(:input, non_null(:smart_contract_input))
      middleware(MDowncase, [:contract_address])
      resolve(&Resolvers.SmartContract.smart_contract/3)
    end

    @desc """
    function: get list of smart contracts

    request-example:
    query {
      smart_contracts {
        name
        account_id
        account {
          eth_address
        }
      }
    }

    result-example:
    {
      "data": {
        "smart_contracts": [
          {
            "account": {
              "eth_address": "0x21c814bf216ec7b988d872c56bf948d9cc1638a2"
            },
            "account_id": "3014",
            "name": "YOKAI"
          }
        ]
      }
    }
    """
    field :smart_contracts, list_of(:smart_contract) do
      arg(:input, :page_and_size_input, default_value: %{page: 1, page_size: 20, sort_type: :asc})
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

    field :account, :account do
    resolve(&Resolvers.SmartContract.account/3)
    end
  end

  input_object :smart_contract_input do
    field :contract_address, non_null(:string)
  end

  input_object :smart_contracts_input do
    import_fields :page_and_size_input
    import_fields :sort_type_input
  end
end
