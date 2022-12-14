defmodule GodwokenExplorer.Graphql.Types.Block do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :block_querys do
    @desc """
    function: get block by block number or block hash
    request-result-example:
    ```
    query {
      block(input: {number: 1}){
        hash
        parent_hash
        number
        gas_used
        gas_limit
        account{
          id
          eth_address
        }
        transactions (input: {page: 1, page_size: 2}) {
          type
          from_account_id
          to_account_id
        }
      }
    }
    ```
    ```
    {
      "data": {
        "block": {
          "account": null,
          "gas_limit": "12500000",
          "gas_used": "0",
          "hash": "0x4ac339b063e52dac1b845d935788f379ebcdb0e33ecce077519f39929dbc8829",
          "number": 1,
          "parent_hash": "0x61bcff6f20e8be09bbe8e36092a9cc05dd3fa67e3841e206e8c30ae0dd7032df",
          "transactions": []
        }
      }
    }
    ```
    """
    field :block, :block do
      arg(:input, :block_input)
      resolve(&Resolvers.Block.block/3)
    end

    @desc """
    function: get list of block sort by block number
    request-example:
    ```
    query {
      blocks(input: {}){
        hash
        parent_hash
        number
        gas_used
        gas_limit
        producer_address
        account{
          eth_address
        }
        transactions (input: {page: 1, page_size: 2}) {
          type
          from_account_id
          to_account_id
        }
      }
    }
    ```
    ```
    result-example:
    {
      "data": {
        "block": {
          "account": null,
          "gas_limit": "12500000",
          "gas_used": "0",
          "hash": "0x089f36f4f1eb1060e12ade101e4a6326423fa6cd11915d9bf1ef4bacafdbe663",
          "number": 14938,
          "parent_hash": "0xa552df86bad0233d0acb183056b095ac50abfa93161ff6b62ebe52bac2e53776",
          "producer_address": "715ab282b873b79a7be8b0e8c13c4e8966a52040",
          "transactions": []
        }
      }
    }
    ```
    """
    field :blocks, list_of(:block) do
      arg(:input, :blocks_input, default_value: %{page: 1, page_size: 10, sort_type: :desc})
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.Block.blocks/3)
    end
  end

  object :block_mutations do
  end

  object :block do
    field :hash, :hash_full, description: "The current block hash."
    field :number, :integer, description: "The block number, start with 0."
    field :parent_hash, :hash_full, description: "The parent block hash."
    field :timestamp, :datetime, description: "When the block was collated."

    field :status, :block_status,
      description:
        "Committed means block submit to layer1(CKB) and can be challenged;Finalized means block can't be challenged."

    field :transaction_count, :integer, description: "The block contains transaction count."
    field :layer1_tx_hash, :hash_full, description: "Finalized at which layer1 transaction hash."
    field :layer1_block_number, :integer, description: "Finalized at which layer1 block number."
    field :size, :integer, description: "The size of the block in bytes."
    field :gas_limit, :decimal, description: "Gas limit of this block."
    field :gas_used, :decimal, description: "Actual used gas."

    field :logs_bloom, :string,
      description:
        "the [Bloom filter](https://en.wikipedia.org/wiki/Bloom_filter) for the logs of the block."

    field :registry_id, :integer, description: "The block producer registers by which account id."
    field :producer_address, :hash_address, description: "The block produced by which account."

    field :account, :account, resolve: dataloader(:graphql)
  end

  enum :block_status do
    value(:committed)
    value(:finalized)
  end

  input_object :block_input do
    field :hash, :hash_full
    field :number, :integer
  end

  input_object :blocks_input do
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
  end
end
