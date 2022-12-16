defmodule GodwokenExplorer.Graphql.Types.Address do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :address_querys do
    @desc """
    function: get address by addresses
    request-with-address-example:
    ```
    query {
      address(input: {address: "0x59b670e9fa9d0a427751af201d676719a970857b"}){
        eth_address
        bit_alias
        token_transfer_count
      }
    }
    ```
    ```
    {
      "data": {
        "address": {
          "eth_address": "0x59b670e9fa9d0a427751af201d676719a970857b",
          "bit_alias": "test.bit",
          token_transfer_count: 0
        }
      }
    }
    ```
    """
    field :address, :address do
      arg(:input, non_null(:address_input))
      resolve(&Resolvers.Address.address/3)
    end
  end

  object :address do
    field :eth_address, :hash_full, description: "The address that not exist in godwoken chain."
    field :token_transfer_count, :integer, description: "The address cached token transfer count."
    field :bit_alias, :string, description: ".bit alias."
  end

  input_object :address_input do
    @desc """
    ```
    address: eth_address
    example: "0x59b670e9fa9d0a427751af201d676719a970857b"
    ```
    """
    field :address, :hash_address
  end

  input_object :address_child_udts_input do
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
  end
end
