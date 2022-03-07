defmodule GodwokenExplorer.Graphql.Types.History do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :history_querys do
    field :withdrawal_histories, list_of(:withdrawal_history) do
      arg :input, :withdrawal_history_input
      resolve(&Resolvers.History.withdrawal_historys/3)
    end

    field :deposit_histories, list_of(:deposit_history) do
      arg :input, :deposit_history_input
      resolve(&Resolvers.History.deposit_histories/3)
    end

    field :withdrawal_requests, list_of(:withdrawal_request) do
      arg :input, :withdrawal_request_input
      resolve(&Resolvers.History.withdrawal_requests/3)
    end
  end

  object :withdrawal_history do
    field :id, :integer
    field :block_hash, :string
    field :block_number, :integer
    field :layer1_block_number, :integer
    field :l2_script_hash, :string
    field :layer1_output_index, :integer
    field :layer1_tx_hash, :string
    field :owner_lock_hash, :string
    field :payment_lock_hash, :string
    field :sell_amount, :decimal
    field :sell_capacity, :decimal
    field :udt_script_hash, :string
    field :amount, :decimal
    field :udt_id, :integer
    field :timestamp, :datetime
    field :state, :withdrawal_history_state
  end

  object :deposit_history do
    field :id, :integer
    field :script_hash, :string
    field :amount, :decimal
    field :udt_id, :integer
    field :layer1_block_number, :integer
    field :layer1_tx_hash, :string
    field :layer1_output_index, :integer
    field :ckb_lock_hash, :string
    field :timestamp, :datetime
  end

  object :withdrawal_request do
    field :id, :integer
    field :nonce, :integer
    field :capacity, :decimal
    field :amount, :decimal
    field :sell_amount, :decimal
    field :sell_capacity, :decimal
    field :sudt_script_hash, :string
    field :account_script_hash, :string
    field :owner_lock_hash, :string
    field :payment_lock_hash, :string
    field :fee_amount, :decimal
    field :fee_udt_id, :integer
    field :udt_id, :integer
    field :block_hash, :string
    field :block_number, :integer
  end

  enum :withdrawal_history_state do
    value :pending
    value :available
    value :succeed
  end

  input_object :withdrawal_history_input do
    field :owner_lock_hash, :string
    field :l2_script_hash, :string
    field :eth_address, :string
    import_fields :page_and_size_input
  end

  input_object :deposit_history_input do
    field :eth_address, :string
    import_fields :page_and_size_input
  end

  input_object :withdrawal_request_input do
    field :eth_address, :string
    import_fields :page_and_size_input
  end
end
