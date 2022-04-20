defmodule GodwokenExplorer.Graphql.Types.TokenTransfer do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :token_transfer_querys do

    @desc """
    function: get list of token transfers by filter

    request-example:
    query {
      token_transfers(input: {from_address_hash: "0x3770f660a5b6fde2dadd765c0f336543ff285097", start_block_number: 300000, end_block_number:344620, page: 1, page_size: 1, sort_type: DESC}) {
        transaction_hash
        block_number
        to_account{
          id
          short_address
        }
        to_address_hash
        from_account{
          id
          short_address
        }
      }
    }

    result-example:
    {
      "data": {
        "token_transfers": [
          {
            "block_number": 344620,
            "from_account": {
              "id": 53057,
              "short_address": "0x3770f660a5b6fde2dadd765c0f336543ff285097"
            },
            "to_account": {
              "id": 53057,
              "short_address": "0x3770f660a5b6fde2dadd765c0f336543ff285097"
            },
            "to_address_hash": "0x3770f660a5b6fde2dadd765c0f336543ff285097",
            "transaction_hash": "0xf6caf10b0a43adaabd08ef00fde03aa6d25310a1872dd08e7a7a4a4d3bd82301"
          }
        ]
      }
    }
    """
    field :token_transfers, list_of(:token_transfer) do
      arg(:input, non_null(:token_transfer_input))
      resolve(&Resolvers.TokenTransfer.token_transfers/3)
    end
  end

  object :token_transfer do
    field :transaction_hash, :string
    field :amount, :decimal
    field :block_number, :integer
    field :block_hash, :string
    field :log_index, :integer
    field :token_id, :decimal
    field :from_address_hash, :string
    field :to_address_hash, :string
    field :token_contract_address_hash, :string

    field :polyjuice, :polyjuice do
      resolve(&Resolvers.TokenTransfer.polyjuice/3)
    end

    field :from_account, :account do
      resolve(&Resolvers.TokenTransfer.from_account/3)
    end

    field :to_account, :account do
      resolve(&Resolvers.TokenTransfer.to_account/3)
    end

    field :udt, :udt do
      resolve(&Resolvers.TokenTransfer.udt/3)
    end

    field :block, :block do
      resolve(&Resolvers.TokenTransfer.block/3)
    end

    field :transaction, :transaction do
      resolve(&Resolvers.TokenTransfer.transaction/3)
    end
  end

  input_object :token_transfer_input do
    field :transaction_hash, :string
    field :from_address_hash, :string
    field :to_address_hash, :string
    field :token_contract_address_hash, :string
    import_fields(:page_and_size_input)
    import_fields(:block_range_input)
    import_fields(:sort_type_input)
  end
end
