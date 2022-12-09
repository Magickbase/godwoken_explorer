defmodule GodwokenExplorer.Graphql.Types.Polyjuice do
  use Absinthe.Schema.Notation

  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :polyjuice do
    field :id, :integer, description: "ID of polyjuice table."
    field :is_create, :boolean, description: "This transaction deployed contract."
    field :gas_limit, :bigint, description: "Gas limited value."
    field :gas_price, :bigint, description: "How much the sender is willing to pay for `gas`."
    field :value, :bigint, description: " pCKB transferred from `from_address` to `to_address`."
    field :input_size, :integer, description: "Data size."
    field :input, :chain_data, description: "Data sent along with the transaction."
    field :tx_hash, :hash_full, description: "The godwoken transaction hash."

    field :eth_hash, :hash_full do
      description("The polyjuce eth transaction hash.")
      resolve(&Resolvers.Polyjuice.eth_hash/3)
    end

    field :transaction, :transaction, resolve: dataloader(:graphql)

    field :gas_used, :bigint,
      description:
        "The gas used for just `transaction`.  `nil` when transaction is pending or has only been collated into one of the `uncles` in one of the `forks`."

    field :transaction_index, :integer,
      description:
        "Index of this transaction in `block`.  `nil` when transaction is pending or has only been collated into one of the `uncles` in one of the `forks`."

    field :created_contract_address_hash, :hash_address,
      description: "This transaction deployed contract address."

    field :native_transfer_address_hash, :hash_address,
      description:
        "If this transaction is native transfer, to_address is a contract, this column is actual receiver."

    field :status, :polyjuice_status, description: "Status of deployed."
  end

  object :polyjuice_creator do
    field :id, :integer, description: "ID of polyjuice_creator table."
    field :code_hash, :string, description: "Layer2 account code_hash."
    field :hash_type, :string, description: "Layer2 account hash_type."
    field :script_args, :string, description: "Layer2 account script_args."
    field :tx_hash, :hash_full, description: "The transaction foreign key."
    field :fee_amount, :bigint, description: "The tranasaction used fee."
    field :fee_udt_id, :integer, description: "The transaction registry by which account."

    field :created_account, :account do
      description("The mapping account which created.")
      resolve(&Resolvers.Polyjuice.created_account/3)
    end
  end

  enum :polyjuice_status do
    value(:succeed)
    value(:failed)
  end
end
