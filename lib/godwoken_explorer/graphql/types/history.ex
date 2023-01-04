defmodule GodwokenExplorer.Graphql.Types.History do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :history_querys do
    field :deposit_withdrawal_histories, :paginate_deposit_withdrawal_histories do
      arg(:input, :histories_input)
      resolve(&Resolvers.History.deposit_withdrawal_histories/3)
    end
  end

  object :paginate_deposit_withdrawal_histories do
    field :entries, list_of(:deposit_withdrawal_history)
    field :metadata, :paginate_metadata
  end

  object :deposit_withdrawal_history do
    field :script_hash, :hash_full
    field :eth_address, :hash_address
    field :value, :decimal
    field :owner_lock_hash, :hash_full
    field :sudt_script_hash, :hash_full
    field :block_hash, :hash_full
    field :block_number, :integer
    field :timestamp, :datetime
    field :layer1_block_number, :integer
    field :layer1_tx_hash, :hash_full
    field :layer1_output_index, :hash_full
    field :ckb_lock_hash, :hash_full
    field :state, :withdrawal_history_state
    field :type, :deposit_withdrawal_type
    field :capacity, :decimal

    field :udt, :udt do
      resolve(&Resolvers.History.udt/3)
    end
  end

  object :withdrawal_history do
    field :id, :integer
    field :block_hash, :hash_full
    field :block_number, :integer
    field :layer1_block_number, :integer
    field :layer1_output_index, :integer
    field :layer1_tx_hash, :hash_full
    field :l2_script_hash, :hash_full
    field :owner_lock_hash, :hash_full
    field :udt_script_hash, :hash_full
    field :amount, :decimal
    field :udt_id, :integer
    field :timestamp, :datetime
    field :state, :withdrawal_history_state
    field :capacity, :decimal

    field :udt, :udt, resolve: dataloader(:graphql)
  end

  object :deposit_history do
    field :id, :integer
    field :script_hash, :hash_full
    field :amount, :decimal
    field :udt_id, :integer
    field :layer1_block_number, :integer
    field :layer1_tx_hash, :hash_full
    field :layer1_output_index, :integer
    field :ckb_lock_hash, :hash_full
    field :timestamp, :datetime
    field :capacity, :decimal
    field :udt_script_hash, :hash_full
    field :udt, :udt, resolve: dataloader(:graphql)
  end

  object :withdrawal_request do
    field :id, :integer
    field :hash, :hash_full
    field :nonce, :integer
    field :capacity, :decimal
    field :amount, :decimal
    field :sudt_script_hash, :hash_full
    field :account_script_hash, :hash_full
    field :owner_lock_hash, :hash_full
    field :fee_amount, :decimal
    field :block_hash, :hash_full
    field :block_number, :integer
    field :chain_id, :integer
    field :registry_id, :integer
    field :udt_id, :integer

    field :udt, :udt, resolve: dataloader(:graphql)
  end

  enum :deposit_withdrawal_type do
    value(:deposit)
    value(:withdrawal)
  end

  enum :withdrawal_history_state do
    value(:pending)
    value(:available)
    value(:succeed)
  end

  enum :histories_sorter do
    value(:timestamp)
  end

  input_object :histories_sorter_input do
    field :sort_type, :sort_type
    field :sort_value, :histories_sorter
  end

  input_object :histories_input do
    field :eth_address, :hash_address
    field :udt_id, :integer
    import_fields(:block_range_input)
    import_fields(:paginate_input)

    field :sorter, list_of(:histories_sorter_input),
      default_value: [
        %{sort_type: :desc, sort_value: :timestamp}
      ]
  end
end
