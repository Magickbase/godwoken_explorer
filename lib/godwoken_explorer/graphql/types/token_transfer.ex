defmodule GodwokenExplorer.Graphql.Types.TokenTransfer do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.EIP55, as: MEIP55
  alias GodwokenExplorer.Graphql.Middleware.Downcase, as: MDowncase

  object :token_transfer_querys do
    @desc """
    function: get list of token transfers by filter

    request-result-example:
    query {
      token_transfers(
        input: {
          from_address: "0x966b30e576a4d6731996748b48dd67c94ef29067"
          to_address: "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413"
          start_block_number: 1
          end_block_number: 11904
          limit: 10
          sort_type: DESC
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
              "block_number": 11904,
              "from_account": {
                "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067"
              },
              "to_account": {
                "eth_address": "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413"
              },
              "to_address": "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413",
              "transaction_hash": "0xaf0be54aadf00c5717e9380269146ab7e330cc195a2e5c181480aef1a4f552e7"
            },
            {
              "block_number": 11904,
              "from_account": {
                "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067"
              },
              "to_account": {
                "eth_address": "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413"
              },
              "to_address": "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413",
              "transaction_hash": "0x954fd1d5645c49c62008a842839fc9ea134453aa0e30120af23f78fac276b33b"
            },
            {
              "block_number": 11904,
              "from_account": {
                "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067"
              },
              "to_account": {
                "eth_address": "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413"
              },
              "to_address": "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413",
              "transaction_hash": "0x934d9c939dcabf5c03c2828b0d74262a5c9b0aa86732a8cfc7bc03c8830bd1fc"
            },
            {
              "block_number": 11904,
              "from_account": {
                "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067"
              },
              "to_account": {
                "eth_address": "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413"
              },
              "to_address": "0xbd6250d17fc557dfe39a9eb3882c421d4c7f6413",
              "transaction_hash": "0x2c70095a3a15a173517fc8d95c505add5242c3287da72907f5ffa1c0b6cc9578"
            }
          ],
          "metadata": {
            "after": null,
            "before": null,
            "total_count": 4
          }
        }
      }
    }
    """
    field :token_transfers, :paginate_token_transfers do
      arg(:input, non_null(:token_transfer_input))

      middleware(MEIP55, [
        :from_address,
        :to_address,
        :token_contract_address_hash
      ])

      middleware(MDowncase, [
        :transaction_hash,
        :from_address,
        :to_address,
        :token_contract_address_hash
      ])

      resolve(&Resolvers.TokenTransfer.token_transfers/3)
    end
  end

  object :paginate_token_transfers do
    field :entries, list_of(:token_transfer)
    field :metadata, :paginate_metadata
  end

  object :token_transfer do
    field :transaction_hash, :string
    field :amount, :decimal
    field :block_number, :integer
    field :block_hash, :string
    field :log_index, :integer
    field :token_id, :decimal

    field :from_address, :string do
      resolve(&Resolvers.TokenTransfer.from_address/3)
    end

    field :to_address, :string do
      resolve(&Resolvers.TokenTransfer.to_address/3)
    end

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
    field :from_address, :string
    field :to_address, :string
    field :token_contract_address_hash, :string
    import_fields(:paginate_input)
    import_fields(:block_range_input)
    import_fields(:sort_type_input)
  end
end
