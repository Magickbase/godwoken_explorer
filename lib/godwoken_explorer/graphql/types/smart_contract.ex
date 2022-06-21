defmodule GodwokenExplorer.Graphql.Types.SmartContract do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :smart_contract_querys do
    @desc """
    function: get smart contract by address

    request-result-example:
    query {
      smart_contract(
        input: { contract_address: "0x2503A1A79A443F3961EE96A8C5EC513638129614" }
      ) {
        name
        account_id
        account {
          eth_address
        }
      }
    }
    {
      "data": {
        "smart_contract": {
          "account": {
            "eth_address": "0x2503a1a79a443f3961ee96a8c5ec513638129614"
          },
          "account_id": "6841",
          "name": "EIP20"
        }
      }
    }

    request-result-example2:
    query {
      smart_contract(
        input: { script_hash: "0x9B55204439C78D3B9CBCC62C03F31E47C8457FD39CA9A9EB805B364B45C26C38" }
      ) {
        name
        account_id
        account {
          eth_address
        }
      }
    }
    {
      "data": {
        "smart_contract": {
          "account": {
            "eth_address": "0x2503a1a79a443f3961ee96a8c5ec513638129614"
          },
          "account_id": "6841",
          "name": "EIP20"
        }
      }
    }

    """
    field :smart_contract, :smart_contract do
      arg(:input, non_null(:smart_contract_input))

      resolve(&Resolvers.SmartContract.smart_contract/3)
    end

    @desc """
    function: get list of smart contracts

    request-example:
    query {
      smart_contracts(input: {page: 1, page_size: 2}) {
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
              "eth_address": "0x2503a1a79a443f3961ee96a8c5ec513638129614"
            },
            "account_id": "6841",
            "name": "EIP20"
          }
        ]
      }
    }
    """
    field :smart_contracts, list_of(:smart_contract) do
      arg(:input, :smart_contracts_input, default_value: %{page: 1, page_size: 20, sort_type: :asc})
      middleware(MTermRange, MTermRange.page_and_size_default_config())
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
    field :deployment_tx_hash, :hash_full
    field :compiler_version, :string
    field :compiler_file_format, :string
    field :other_info, :string

    field :account, :account do
    resolve(&Resolvers.SmartContract.account/3)
    end
  end

  input_object :smart_contract_input do
    field :contract_address, :hash_address
    field :script_hash, :hash_full
  end

  input_object :smart_contracts_input do
    import_fields :page_and_size_input
    import_fields :sort_type_input
  end
end
