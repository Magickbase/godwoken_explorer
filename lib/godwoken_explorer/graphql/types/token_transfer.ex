defmodule GodwokenExplorer.Graphql.Types.TokenTransfer do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :token_transfer_querys do
    @desc """
    function: get list of token transfers by filter

    example:
    query {
      token_transfers(
        input: {
          from_address: "0x966b30e576a4d6731996748b48dd67c94ef29067"
          to_address: "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413"
          start_block_number: 90
          end_block_number: 90
          limit: 2
          combine_from_to: true

          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          transaction_hash
          block_number
          to_account {
            eth_address
          }
          to_address
          from_account {
            eth_address
          }
        }

        metadata {
          total_count
          before
          after
        }
      }
    }

    {
      "data": {
        "token_transfers": {
          "entries": [
            {
              "block_number": 90,
              "from_account": {
                "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067"
              },
              "to_account": {
                "eth_address": "0xc6a44e4d2216a98b3a5086a64a33d94fbcc8fec3"
              },
              "to_address": "0xc6a44e4d2216a98b3a5086a64a33d94fbcc8fec3",
              "transaction_hash": "0x65ea60c7291f5aec6e9f86f6b4af97f6287409fc72f66975af6203721d10d409"
            },
            {
              "block_number": 90,
              "from_account": {
                "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067"
              },
              "to_account": {
                "eth_address": "0xc6a44e4d2216a98b3a5086a64a33d94fbcc8fec3"
              },
              "to_address": "0xc6a44e4d2216a98b3a5086a64a33d94fbcc8fec3",
              "transaction_hash": "0xc3c63aa91100e6c14cea294559eacea33d6a12ed3be89f303247e63f670c2c34"
            }
          ],
          "metadata": {
            "after": "g3QAAAADZAAMYmxvY2tfbnVtYmVyYVpkAAlsb2dfaW5kZXhhAWQAEHRyYW5zYWN0aW9uX2hhc2h0AAAAA2QACl9fc3RydWN0X19kACJFbGl4aXIuR29kd29rZW5FeHBsb3Jlci5DaGFpbi5IYXNoZAAKYnl0ZV9jb3VudGEgZAAFYnl0ZXNtAAAAIMPGOqkRAObBTOopRVnqzqM9ahLtO-ifMDJH5j9nDCw0",
            "before": null,
            "total_count": 3
          }
        }
      }
    }

    example2:
    query {
      token_transfers(
        input: {
          from_address: "0x966b30e576a4d6731996748b48dd67c94ef29067"
          to_address: "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413"
          start_block_number: 90
          end_block_number: 909999
          age_range_start: "2022-06-01T04:59:29"
          age_range_end: "2022-06-01T06:59:29"
          limit: 1
          combine_from_to: true

          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          transaction_hash
          block_number
          updated_at
          to_account {
            eth_address
          }
          to_address
          from_account {
            eth_address
          }
        }

        metadata {
          total_count
          before
          after
        }
      }
    }

    {
      "data": {
        "token_transfers": {
          "entries": [
            {
              "block_number": 1396,
              "from_account": {
                "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067"
              },
              "to_account": {
                "eth_address": "0x074182e2558a108f3f310c29f6fb1b3bd31908ed"
              },
              "to_address": "0x074182e2558a108f3f310c29f6fb1b3bd31908ed",
              "transaction_hash": "0x74c0a1d269a3f8107e5b62f25aad6663f8905086423894c265007b2befc8f919",
              "updated_at": "2022-06-01T05:29:35"
            }
          ],
          "metadata": {
            "after": "g3QAAAADZAAMYmxvY2tfbnVtYmVyYgAABXRkAAlsb2dfaW5kZXhhAWQAEHRyYW5zYWN0aW9uX2hhc2h0AAAAA2QACl9fc3RydWN0X19kACJFbGl4aXIuR29kd29rZW5FeHBsb3Jlci5DaGFpbi5IYXNoZAAKYnl0ZV9jb3VudGEgZAAFYnl0ZXNtAAAAIHTAodJpo_gQflti8lqtZmP4kFCGQjiUwmUAeyvvyPkZ",
            "before": null,
            "total_count": 16
          }
        }
      }
    }
    """
    field :token_transfers, :paginate_token_transfers do
      arg(:input, non_null(:token_transfer_input), default_value: %{})

      resolve(&Resolvers.TokenTransfer.token_transfers/3)
    end
  end

  object :paginate_token_transfers do
    field :entries, list_of(:token_transfer)
    field :metadata, :paginate_metadata
  end

  object :token_transfer do
    field :transaction_hash, :hash_full
    field :amount, :decimal
    field :block_number, :integer
    field :block_hash, :hash_full
    field :log_index, :integer
    field :token_id, :decimal

    field :from_address, :hash_address do
      resolve(&Resolvers.TokenTransfer.from_address/3)
    end

    field :to_address, :hash_address do
      resolve(&Resolvers.TokenTransfer.to_address/3)
    end

    field :token_contract_address_hash, :hash_address

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

    import_fields(:ecto_naive_datetime)
  end

  enum :token_transfers_sorter do
    value(:block_number)
    value(:transaction_hash)
    value(:log_index)
    # value(:updated_at)
  end

  input_object :token_transfer_input do
    field :transaction_hash, :hash_full

    field :sorter, list_of(:token_transfers_sorter_input),
      default_value: [
        %{sort_type: :desc, sort_value: :block_number},
        %{sort_type: :desc, sort_value: :log_index},
        %{sort_type: :asc, sort_value: :transaction_hash}
      ]

    field :from_address, :hash_address
    field :to_address, :hash_address

    @desc """
    if combine_from_to is true, then from_address and to_address are combined into query condition like `address = from_address OR address = to_address`
    """
    field :combine_from_to, :boolean, default_value: true
    field :token_contract_address_hash, :hash_address
    import_fields(:age_range_input)
    import_fields(:paginate_input)
    import_fields(:block_range_input)
  end

  input_object :token_transfers_sorter_input do
    field :sort_type, :sort_type
    field :sort_value, :token_transfers_sorter
  end
end
