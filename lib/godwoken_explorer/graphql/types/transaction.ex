defmodule GodwokenExplorer.Graphql.Types.Transaction do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.EIP55, as: MEIP55
  alias GodwokenExplorer.Graphql.Middleware.Downcase, as: MDowncase

  object :transaction_querys do
    @desc """
    function: get transaction by transaction_hash

    request-example:
    query {
      transaction(
        input: {
          eth_hash: "0xcdbda9ec578e73e886446d3bd5ca070d77a908be4187fc0e835c7c1598a3fcfa"
        }
      ) {
        hash
        nonce
        type
        index
        from_account {
          eth_address
          type
        }
        to_account {
          eth_address
          type
        }
        polyjuice {
          is_create
          value
          status
          input
          created_contract_address_hash
          gas_used
          gas_limit
          gas_price
        }
        block {
          number
          hash
          timestamp
          status
          layer1_block_number
        }
      }
    }


    result-example:
    {
      "data": {
        "transaction": {
          "block": {
            "hash": "0x08b5d6747151e7cc0a2ffd81505d3db39af268c9c1c753a22e7c80890e3b94c5",
            "layer1_block_number": 5293647,
            "number": 81,
            "status": "FINALIZED",
            "timestamp": "2022-05-08T05:15:14.234000Z"
          },
          "from_account": {
            "eth_address": "0x966b30e576a4d6731996748b48dd67c94ef29067",
            "type": "ETH_USER"
          },
          "hash": "0xc7ab89121ab5727b09e007cc04176216e4d5fab1fb0ebe33320b7075e7e54533",
          "index": 0,
          "nonce": 0,
          "polyjuice": {
            "created_contract_address_hash": "0xf9f9bd767dd10ad384182769d47d9e239f281bcd",
            "gas_limit": "245",
            "gas_price": "1",
            "gas_used": "245",
            "input": "0x608060405234801561001057600080fd5b506103e2806100206000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c80636fd902e11161005b5780636fd902e114610105578063796b89b9146101235780637c0dacdb14610141578063ee82ac5e1461014b57610088565b806312e05dd11461008d5780632df8e949146100ab5780633408e470146100c957806342cbb15c146100e7575b600080fd5b61009561017b565b6040516100a291906102a3565b60405180910390f35b6100b3610183565b6040516100c0919061026d565b60405180910390f35b6100d161018b565b6040516100de91906102a3565b60405180910390f35b6100ef610193565b6040516100fc91906102a3565b60405180910390f35b61010d6101a7565b60405161011a91906102a3565b60405180910390f35b61012b6101af565b60405161013891906102a3565b60405180910390f35b6101496101b7565b005b61016560048036038101906101609190610213565b6101f3565b6040516101729190610288565b60405180910390f35b600044905090565b600041905090565b600046905090565b60006001436101a291906102e7565b905090565b600043905090565b600042905090565b7f95e0325a2d4f803db1237b0e454f7d9a09ec46941e478e3e98c510d8f15060314343406040516101e99291906102be565b60405180910390a1565b600081409050919050565b60008135905061020d81610395565b92915050565b60006020828403121561022957610228610390565b5b6000610237848285016101fe565b91505092915050565b6102498161031b565b82525050565b6102588161032d565b82525050565b61026781610357565b82525050565b60006020820190506102826000830184610240565b92915050565b600060208201905061029d600083018461024f565b92915050565b60006020820190506102b8600083018461025e565b92915050565b60006040820190506102d3600083018561025e565b6102e0602083018461024f565b9392505050565b60006102f282610357565b91506102fd83610357565b9250828210156103105761030f610361565b5b828203905092915050565b600061032682610337565b9050919050565b6000819050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b600080fd5b61039e81610357565b81146103a957600080fd5b5056fea2646970667358221220d273a25c31e711ab76ca9928e49a2f327bab9ac3707697ef7567ca28d6673d3a64736f6c63430008060033",
            "is_create": true,
            "status": "SUCCEED",
            "value": "0"
          },
          "to_account": {
            "eth_address": "0x2f760c8f8656bde4995f26b8963e2dd801000000",
            "type": "POLYJUICE_CREATOR"
          },
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
      transactions(
        input: {
          address: "0x57f2e7809ec800ea742fa7a5974aa106b14afab5"
          end_block_number: 4000
          sort_type: DESC
          limit: 2
        }
      ) {
        entries {
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

        metadata {
          total_count
          before
          after
        }
      }
    }

    {
      "data": {
        "transactions": {
          "entries": [
            {
              "block_hash": "0x2f85c0b373c7bd770478472dd03c0b66cb4656184aaa99d49b666122c2bfe703",
              "block_number": 3971,
              "from_account": {
                "eth_address": "0x57f2e7809ec800ea742fa7a5974aa106b14afab5",
                "id": 110
              },
              "from_account_id": 110,
              "to_account_id": 136,
              "type": "POLYJUICE"
            },
            {
              "block_hash": "0x2f85c0b373c7bd770478472dd03c0b66cb4656184aaa99d49b666122c2bfe703",
              "block_number": 3971,
              "from_account": {
                "eth_address": "0x57f2e7809ec800ea742fa7a5974aa106b14afab5",
                "id": 110
              },
              "from_account_id": 110,
              "to_account_id": 137,
              "type": "POLYJUICE"
            }
          ],
          "metadata": {
            "after": "g3QAAAADZAAMYmxvY2tfbnVtYmVyYgAAD4NkAARoYXNobQAAAEIweDU0MzNiMTE5ZmIwNTQ4NjM0YTY0NDAwNjZmNzUxNThlYWMyODk0MDgxNmU4YzlkYmVjZTk2ZTczMGUwMWU3MjZkAAVpbmRleGEA",
            "before": null,
            "total_count": 77
          }
        }
      }
    }
    """
    field :transactions, :paginate_trasactions do
      arg(:input, non_null(:transactions_input))
      middleware(MEIP55, [:address])
      middleware(MDowncase, [:address])
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

  object :paginate_trasactions do
    field :entries, list_of(:transaction)
    field :metadata, :paginate_metadata
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
    import_fields(:paginate_input)
    import_fields(:sort_type_input)
    import_fields(:block_range_input)
  end
end
