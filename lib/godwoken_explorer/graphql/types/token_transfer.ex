defmodule GodwokenExplorer.Graphql.Types.TokenTransfer do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.NullFilter

  object :token_transfer_querys do
    @desc """
    function: get list of token transfers by filter
    example:
    ```
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
    ```
    ```
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
    ```
    example2:
    ```
    query {
      token_transfers(
        input: {
          from_address: "0x966b30e576a4d6731996748b48dd67c94ef29067"
          to_address: "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413"
          start_block_number: 90
          end_block_number: 909999
          age_range_end: "2022-05-08T05:19:26.237000Z"
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
          block {
            timestamp
          }
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
    ```
    ```
    {
      "data": {
        "token_transfers": {
          "entries": [
            {
              "block": {
                "timestamp": "2022-05-08T05:19:25.237000Z"
              },
              "block_number": 90,
              "from_account": {
                "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067"
              },
              "to_account": {
                "eth_address": "0xc6a44e4d2216a98b3a5086a64a33d94fbcc8fec3"
              },
              "to_address": "0xc6a44e4d2216a98b3a5086a64a33d94fbcc8fec3",
              "transaction_hash": "0x65ea60c7291f5aec6e9f86f6b4af97f6287409fc72f66975af6203721d10d409"
            }
          ],
          "metadata": {
            "after": "g3QAAAADZAAMYmxvY2tfbnVtYmVyYVpkAAlsb2dfaW5kZXhhAWQAEHRyYW5zYWN0aW9uX2hhc2h0AAAAA2QACl9fc3RydWN0X19kACJFbGl4aXIuR29kd29rZW5FeHBsb3Jlci5DaGFpbi5IYXNoZAAKYnl0ZV9jb3VudGEgZAAFYnl0ZXNtAAAAIGXqYMcpH1rsbp-G9rSvl_YodAn8cvZpda9iA3IdENQJ",
            "before": null,
            "total_count": 3
          }
        }
      }
    }
    ```
    """
    field :token_transfers, :paginate_token_transfers do
      arg(:input, non_null(:erc20_token_transfers_input), default_value: %{})
      middleware(NullFilter)
      resolve(&Resolvers.TokenTransfer.erc20_token_transfers/3)
    end

    @desc """
    ```
    query {
      erc721_token_transfers(
        input: {
          to_address: "0x0000000000ce6d8c1fba76f26d6cc5db71432710"
          start_block_number: 90
          end_block_number: 909999
          limit: 1
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          block {
            timestamp
          }
          transaction_hash
          block_number
          to_account {
            eth_address
          }
          to_address
          from_account {
            eth_address
          }
          token_id
          token_ids
        }
        metadata {
          total_count
          before
          after
        }
      }
    }
    ```
    ```
    {
      "data": {
        "erc721_token_transfers": {
          "entries": [
            {
              "block": {
                "timestamp": "2022-08-28T05:15:00.300000Z"
              },
              "block_number": 320956,
              "from_account": null,
              "to_account": {
                "eth_address": "0x0000000000ce6d8c1fba76f26d6cc5db71432710"
              },
              "to_address": "0x0000000000ce6d8c1fba76f26d6cc5db71432710",
              "token_id": "558",
              "token_ids": null,
              "transaction_hash": "0xe10b9659f948de345ab4aa95d8a2ed20e2ac014c44ad7aa7862485973ef3d08f"
            }
          ],
          "metadata": {
            "after": "g3QAAAADZAAMYmxvY2tfbnVtYmVyYgAE5bxkAAlsb2dfaW5kZXhhAGQAEHRyYW5zYWN0aW9uX2hhc2h0AAAAA2QACl9fc3RydWN0X19kACJFbGl4aXIuR29kd29rZW5FeHBsb3Jlci5DaGFpbi5IYXNoZAAKYnl0ZV9jb3VudGEgZAAFYnl0ZXNtAAAAIOELlln5SN40WrSqldii7SDirAFMRK16p4YkhZc-89CP",
            "before": null,
            "total_count": 4
          }
        }
      }
    }
    ```
    """
    field :erc721_token_transfers, :paginate_token_transfers do
      arg(:input, non_null(:erc721_erc1155_token_transfers_input), default_value: %{})
      middleware(NullFilter)
      resolve(&Resolvers.TokenTransfer.erc721_token_transfers/3)
    end

    @desc """
    ```
    query {
      erc1155_token_transfers(
        input: {
          to_address: "0xc6e58fb4affb6ab8a392b7cc23cd3fef74517f6c"
          start_block_number: 0
          end_block_number: 909999
          limit: 1
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          block {
            timestamp
          }
          transaction_hash
          block_number
          to_account {
            eth_address
          }
          to_address
          from_account {
            eth_address
          }
          token_id
          token_ids
          udt{
            id
            name
            eth_type
          }
        }
        metadata {
          total_count
          before
          after
        }
      }
    }
    ```
    ```
    {
      "data": {
        "erc1155_token_transfers": {
          "entries": [
            {
              "block": {
                "timestamp": "2022-07-16T13:47:10.511000Z"
              },
              "block_number": 195916,
              "from_account": null,
              "to_account": {
                "eth_address": "0xc6e58fb4affb6ab8a392b7cc23cd3fef74517f6c"
              },
              "to_address": "0xc6e58fb4affb6ab8a392b7cc23cd3fef74517f6c",
              "token_id": "0",
              "token_ids": null,
              "transaction_hash": "0x9fa88935cd93531dedec0c1b6dd79a0de3e754b5600714d410a85abc3035e7e4",
              "udt": {
                "eth_type": "ERC1155",
                "id": 48435,
                "name": null
              }
            }
          ],
          "metadata": {
            "after": "g3QAAAADZAAMYmxvY2tfbnVtYmVyYgAC_UxkAAlsb2dfaW5kZXhhAGQAEHRyYW5zYWN0aW9uX2hhc2h0AAAAA2QACl9fc3RydWN0X19kACJFbGl4aXIuR29kd29rZW5FeHBsb3Jlci5DaGFpbi5IYXNoZAAKYnl0ZV9jb3VudGEgZAAFYnl0ZXNtAAAAIJ-oiTXNk1Md7ewMG23Xmg3j51S1YAcU1BCoWrwwNefk",
            "before": null,
            "total_count": 10
          }
        }
      }
    }
    ```
    ```
    query {
      erc1155_token_transfers(
        input: {
          to_address: "0xc6e58fb4affb6ab8a392b7cc23cd3fef74517f6c"
          start_block_number: 0
          end_block_number: 909999
          limit: 1
          token_id: "0"
          sorter: [
            { sort_type: ASC, sort_value: BLOCK_NUMBER }
            { sort_type: ASC, sort_value: TRANSACTION_HASH }
            { sort_type: ASC, sort_value: LOG_INDEX }
          ]
        }
      ) {
        entries {
          token_contract_address_hash
          block_number
          token_id
          token_ids
        }
        metadata {
          total_count
          before
          after
        }
      }
    }
    ```
    ```
    {
      "data": {
        "erc1155_token_transfers": {
          "entries": [
            {
              "block_number": 195916,
              "token_contract_address_hash": "0x6e45a282f2176d95a2bccc1a369fc9cb3f0584a0",
              "token_id": "0",
              "token_ids": null
            }
          ],
          "metadata": {
            "after": "g3QAAAADZAAMYmxvY2tfbnVtYmVyYgAC_UxkAAlsb2dfaW5kZXhhAGQAEHRyYW5zYWN0aW9uX2hhc2h0AAAAA2QACl9fc3RydWN0X19kACJFbGl4aXIuR29kd29rZW5FeHBsb3Jlci5DaGFpbi5IYXNoZAAKYnl0ZV9jb3VudGEgZAAFYnl0ZXNtAAAAIJ-oiTXNk1Md7ewMG23Xmg3j51S1YAcU1BCoWrwwNefk",
            "before": null,
            "total_count": 5
          }
        }
      }
    }
    ```
    """
    field :erc1155_token_transfers, :paginate_token_transfers do
      arg(:input, non_null(:erc721_erc1155_token_transfers_input), default_value: %{})
      middleware(NullFilter)
      resolve(&Resolvers.TokenTransfer.erc1155_token_transfers/3)
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

    field :amounts, list_of(:decimal)
    field :token_ids, list_of(:decimal)

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
  end

  enum :token_transfers_sorter do
    value(:block_number)
    value(:transaction_hash)
    value(:log_index)
  end

  input_object :erc721_erc1155_token_transfers_input do
    import_fields(:erc20_token_transfers_input)
    field :token_id, :decimal
  end

  input_object :erc20_token_transfers_input do
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
