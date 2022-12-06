defmodule GodwokenExplorer.Graphql.Types.Search do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :search_querys do
    @desc """
    ```graphql
    search_udt example:
    query {
      search_udt(input: { fuzzy_name: "%ERC%", limit: 1 }) {
        entries {
          id
          name
          symbol
          type
          contract_address_hash
        }
        metadata {
          total_count
          before
          after
        }
      }
    }
    ```
    ```json
    {
      "data": {
        "search_udt": {
          "entries": [
            {
              "contract_address_hash": "0x8e82245c50864754654d2fae31367444e10b990e",
              "id": 89001,
              "name": "testERC20",
              "symbol": "testERC20",
              "type": "NATIVE"
            }
          ],
          "metadata": {
            "after": "g3QAAAABaAJkAARkZXNjZAACaWRiAAFbqQ==",
            "before": null,
            "total_count": 715
          }
        }
      }
    }
    ```
    """
    field :search_udt, :paginate_search_udts do
      arg(:input, non_null(:search_udt_input), default_value: %{})
      resolve(&Resolvers.Search.search_udt/3)
    end
  end

  object :paginate_search_udts do
    field(:entries, list_of(:search_udt_result))
    field(:metadata, :paginate_metadata)
  end

  object :search_udt_result do
    field(:id, :integer, description: "UDT primary key")
    field(:contract_address_hash, :hash_address, description: "The udt contract address.")
    field(:icon, :string, description: "UDT icon url.")

    field :name, :string do
      description(
        "For bridge token, read from [UAN](https://github.com/nervosnetwork/rfcs/pull/335);For native token, read from contract."
      )

      resolve(&Resolvers.UDT.name/3)
    end

    field :symbol, :string do
      description(
        "For bridge token, read from [UAN](https://github.com/nervosnetwork/rfcs/pull/335);For native token, read from contract."
      )

      resolve(&Resolvers.UDT.symbol/3)
    end

    field(:type, :udt_type, description: " Bridge means from layer1;Native means layer2 contract.")

    field :eth_type, :eth_type, description: "EVM token type."
  end

  input_object :search_udt_input do
    field(:fuzzy_name, :string)
    field(:contract_address, :hash_address)
    import_fields(:paginate_input)
  end
end
