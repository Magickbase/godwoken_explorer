defmodule GodwokenExplorer.Graphql.Types.Transaction do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :transaction_querys do
    @desc """
    function: get transaction by transaction_hash

    request-example:
    query {
      transaction (input: {transaction_hash: "0x21d6428f5325fc3632fb4762d40a1833a4e739329ca5bcb1de0a91fb519cf8a4"}) {
        hash
        block_hash
        block_number
        type
        from_account_id
        to_account_id
      }
    }

    result-example:
    {
      "data": {
        "transaction": {
          "block_hash": "0x47d74ac830a8da437da48d95844a9f60c71eaaeffa9e0547738dd49ffe5417cf",
          "block_number": 341275,
          "from_account_id": 27455,
          "hash": "0x21d6428f5325fc3632fb4762d40a1833a4e739329ca5bcb1de0a91fb519cf8a4",
          "to_account_id": 3014,
          "type": "POLYJUICE"
        }
      }
    }

    """
    field :transaction, :transaction do
      arg(:input, non_null(:transaction_hash_input))
      resolve(&Resolvers.Transaction.transaction/3)
    end

    @desc """
    function: list transactions by account address

    request-example:
    query {
      transactions (input: {address: "0xc5e133e6b01b2c335055576c51a53647b1b9b624",  page: 1, page_size: 2, start_block_number: 335796, end_block_number: 341275}) {
        block_hash
        block_number
        type
        from_account_id
        to_account_id
      }
    }

    result-example:
    {
      "data": {
        "transactions": [
          {
            "block_hash": "0x47d74ac830a8da437da48d95844a9f60c71eaaeffa9e0547738dd49ffe5417cf",
            "block_number": 341275,
            "from_account_id": 27455,
            "to_account_id": 3014,
            "type": "POLYJUICE"
          },
          {
            "block_hash": "0xb68eee6a72bfd54a06101bedb264e1026af2228250b82dd7c3f06beb35f5d865",
            "block_number": 335796,
            "from_account_id": 172581,
            "to_account_id": 3014,
            "type": "POLYJUICE"
          }
        ]
      }
    }
    """
    field :transactions, list_of(:transaction) do
      arg(:input, non_null(:transaction_input))
      resolve(&Resolvers.Transaction.transactions/3)
    end
  end

  object :transaction_mutations do
  end

  object :transaction do
    field :hash, :string
    field :args, :string
    field :from_account_id, :integer
    field :nonce, :integer
    field :to_account_id, :integer
    field :type, :transaction_type
    field :block_number, :integer
    field :block_hash, :string

    field :polyjuice, :polyjuice do
      resolve(&Resolvers.Transaction.polyjuice/3)
    end

    field :polyjuice_creator, :polyjuice_creator do
      resolve(&Resolvers.Transaction.polyjuice_creator/3)
    end

    field :from_account, :account do
      resolve(&Resolvers.Transaction.from_account/3)
    end

    field :to_account, :account do
      resolve(&Resolvers.Transaction.to_account/3)
    end

    field :block, :block do
      resolve(&Resolvers.Transaction.block/3)
    end
  end

  enum :transaction_type do
    value(:polyjuice_creator)
    value(:polyjuice)
  end

  input_object :transaction_hash_input do
    field :transaction_hash, non_null(:string)
  end

  input_object :transaction_input do
    field :address, non_null(:string)
    field :sort, :sort_type
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
    import_fields(:block_range_input)
  end
end
