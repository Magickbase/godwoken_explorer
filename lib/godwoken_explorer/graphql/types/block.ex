defmodule GodwokenExplorer.Graphql.Types.Block do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :block_querys do
    @desc """
    function: get block by block number or block hash

    request-example:
    query {
      block(input: {number: 345600}){
        hash
        parent_hash
        number
        gas_used
        gas_limit
        account{
          id
          registry_address
        }
        transactions (input: {page: 1, page_size: 2}) {
          type
          from_account_id
          to_account_id
        }
      }
    }

    result-example:
    {
      "data": {
        "block": {
          "account": {
            "id": 2,
            "registry_address": "0x68f5cea51fa6fcfdcc10f6cddcafa13bf6717436"
          },
          "gas_limit": "981000000",
          "gas_used": "95240385",
          "hash": "0x67dad5ec7f3bc8b5b8f623f4df230cb50c9c39493080a6b32d94023994ba886b",
          "number": 345600,
          "parent_hash": "0x962906210825c339fa4f871239d967c60b62005a6b780ced4334dba56618dbf5",
          "transactions": [
            {
              "from_account_id": 52269,
              "to_account_id": 64241,
              "type": "POLYJUICE"
            },
            {
              "from_account_id": 52920,
              "to_account_id": 197067,
              "type": "POLYJUICE"
            }
          ]
        }
      }
    }
    """
    field :block, :block do
      arg(:input, :block_input)
      resolve(&Resolvers.Block.block/3)
    end

    @desc """
    function: get list of block sort by block number

    request-example:
    query {
      block(input: {number: 14938}){
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
    field :hash, :string
    field :number, :integer
    field :parent_hash, :string
    field :timestamp, :datetime
    field :status, :block_status
    field :transaction_count, :integer
    field :layer1_tx_hash, :string
    field :layer1_block_number, :integer
    field :size, :integer
    field :gas_limit, :decimal
    field :gas_used, :decimal
    field :logs_bloom, :string
    field :difficulty, :decimal
    field :total_difficulty, :decimal
    field :nonce, :string
    field :sha3_uncles, :string
    field :state_root, :string
    field :extra_data, :string
    field :registry_id, :integer
    field :producer_address, :string

    field :account, :account do
      resolve(&Resolvers.Block.account/3)
    end

    field :transactions, list_of(:transaction) do
      arg(:input, :page_and_size_input, default_value: %{page: 1, page_size: 5})
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.Block.transactions/3)
    end
  end

  enum :block_status do
    value(:committed)
    value(:finalized)
  end

  input_object :block_input do
    field :hash, :string
    field :number, :integer
  end

  input_object :blocks_input do
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
  end
end
