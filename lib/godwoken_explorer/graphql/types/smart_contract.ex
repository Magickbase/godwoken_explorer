defmodule GodwokenExplorer.Graphql.Types.SmartContract do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :smart_contract_querys do
    @desc """
    function: get smart contract by address
    request-result-example:
    ```
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
    ```
    ```
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
    ```
    request-result-example2:
    ```
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
    ```
    ```
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
    ```
    """
    field :smart_contract, :smart_contract do
      arg(:input, non_null(:smart_contract_input))

      resolve(&Resolvers.SmartContract.smart_contract/3)
    end

    @desc """
    function: get list of smart contracts
    request-result-example:
    ```
    query {
      smart_contracts(input: { sorter: [{ sort_type: ASC, sort_value: ID }] }) {
        entries {
          name
          account_id
          account {
            eth_address
          }
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    ```
    ```
    {
      "data": {
        "smart_contracts": {
          "entries": [
            {
              "account": {
                "eth_address": "0x2503a1a79a443f3961ee96a8c5ec513638129614"
              },
              "account_id": "6841",
              "name": "EIP20"
            }
          ],
          "metadata": {
            "after": null,
            "before": null,
            "total_count": 1
          }
        }
      }
    }
    ```
    multi-table-sorter-example:
    ```
    query {
      smart_contracts(
        input: { sorter: [{ sort_type: ASC, sort_value: EX_TX_COUNT }] }
      ) {
        entries {
          name
          account_id
          account {
            eth_address
          }
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    ```
    ```
    {
      "data": {
        "smart_contracts": {
          "entries": [
            {
              "account": {
                "eth_address": "0x2503a1a79a443f3961ee96a8c5ec513638129614"
              },
              "account_id": "6841",
              "name": "EIP20"
            }
          ],
          "metadata": {
            "after": null,
            "before": null,
            "total_count": 1
          }
        }
      }
    }
    ```
    """
    field :smart_contracts, :paginate_smart_contracts do
      arg(:input, :smart_contracts_input)
      resolve(&Resolvers.SmartContract.smart_contracts/3)
    end
  end

  object :paginate_smart_contracts do
    field :entries, list_of(:smart_contract)
    field :metadata, :paginate_metadata
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

  enum :smart_contracts_sorter do
    value(:id)
    value(:name)
    # value(:ex_balance)
    value(:ex_tx_count)
  end

  input_object :smart_contract_input do
    field :contract_address, :hash_address
    field :script_hash, :hash_full
  end

  input_object :smart_contracts_input do
    import_fields(:paginate_input)

    field :sorter, list_of(:smart_contracts_sorter_input),
      default_value: [
        %{sort_type: :asc, sort_value: :id},
        %{sort_type: :asc, sort_value: :name}
      ]
  end

  input_object :smart_contracts_sorter_input do
    field :sort_type, :sort_type
    field :sort_value, :smart_contracts_sorter
  end
end
