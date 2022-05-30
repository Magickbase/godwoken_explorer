defmodule GodwokenExplorer.Graphql.Types.Transaction do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.EIP55, as: MEIP55
  alias GodwokenExplorer.Graphql.Middleware.Downcase, as: MDowncase
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :transaction_querys do
    @desc """
    function: get transaction by transaction_hash

    request-example:
    query {
      transaction (input: {transaction_hash: "0xc7ab89121ab5727b09e007cc04176216e4d5fab1fb0ebe33320b7075e7e54533"}) {
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
          "block_hash": "0x08b5d6747151e7cc0a2ffd81505d3db39af268c9c1c753a22e7c80890e3b94c5",
          "block_number": 81,
          "from_account_id": 5,
          "hash": "0xc7ab89121ab5727b09e007cc04176216e4d5fab1fb0ebe33320b7075e7e54533",
          "to_account_id": 4,
          "type": "POLYJUICE"
        }
      }
    }

    request-example-2:
    query {
      transaction (input: {eth_hash: "0xcdbda9ec578e73e886446d3bd5ca070d77a908be4187fc0e835c7c1598a3fcfa"}) {
        hash
        eth_hash
        block_hash
        block_number
        type
        from_account_id
        to_account_id
      }
    }

    result-example-2:
    {
      "data": {
        "transaction": {
          "block_hash": "0x08b5d6747151e7cc0a2ffd81505d3db39af268c9c1c753a22e7c80890e3b94c5",
          "block_number": 81,
          "eth_hash": "0xcdbda9ec578e73e886446d3bd5ca070d77a908be4187fc0e835c7c1598a3fcfa",
          "from_account_id": 5,
          "hash": "0xc7ab89121ab5727b09e007cc04176216e4d5fab1fb0ebe33320b7075e7e54533",
          "to_account_id": 4,
          "type": "POLYJUICE"
        }
      }
    }
    """
    field :transaction, :transaction do
      arg(:input, non_null(:transaction_input))
      middleware(MDowncase, [:transaction_hash, :eth_hash])
      resolve(&Resolvers.Transaction.transaction/3)
    end

    @desc """
    function: list transactions by account address

    request-example:
    query {
      transactions (input: {address: "0x966b30e576a4d6731996748b48dd67c94ef29067",  page: 1, page_size: 2, end_block_number: 15408}) {
        block_hash
        block_number
        type
        from_account_id
    from_account {
          id
          eth_address
        }
        to_account_id
      }

    }

    {
      "data": {
        "transactions": [
          {
            "block_hash": "0x50505f785e5bfa7b5b13a440eea7b4701368fd539a405d50a03f114ea886e41a",
            "block_number": 15408,
            "from_account": {
              "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067",
              "id": 5
            },
            "from_account_id": 5,
            "to_account_id": 1003,
            "type": "POLYJUICE"
          },
          {
            "block_hash": "0x50505f785e5bfa7b5b13a440eea7b4701368fd539a405d50a03f114ea886e41a",
            "block_number": 15408,
            "from_account": {
              "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067",
              "id": 5
            },
            "from_account_id": 5,
            "to_account_id": 4,
            "type": "POLYJUICE"
          }
        ]
      }
    }
    """
    field :transactions, list_of(:transaction) do
      arg(:input, non_null(:transactions_input))
      middleware(MEIP55, [:address])
      middleware(MDowncase, [:address])
      middleware(MTermRange, MTermRange.page_and_size_default_config())
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
    field :eth_hash, :string
    field(:index, :integer)

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
    value(:eth_address_registry)
  end

  input_object :transaction_input do
    field :transaction_hash, :string
    field :eth_hash, :string
  end

  input_object :transactions_input do
    field :address, non_null(:string)
    field :sort, :sort_type
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
    import_fields(:block_range_input)
  end
end
