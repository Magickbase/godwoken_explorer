defmodule GodwokenExplorer.Graphql.Types.Log do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.Downcase, as: MDowncase

  object :log_querys do
    @desc """
    function: get list of logs by filter or conditions
    request-example:
    ```
    query {
      logs(input: {first_topic: "0x95e0325a2d4f803db1237b0e454f7d9a09ec46941e478e3e98c510d8f1506031",end_block_number: 9988, page: 1, page_size: 1}) {
        transaction_hash
        block_number
        address_hash
        data
        first_topic
        second_topic
        third_topic
        fourth_topic
      }
    }
    ```
    ```
    {
      "data": {
        "logs": [
          {
            "address_hash": "0x6589f40e144a03da53234dc98a47da36160dbf77",
            "block_number": 9988,
            "data": "0x00000000000000000000000000000000000000000000000000000000000027040000000000000000000000000000000000000000000000000000000000000000",
            "first_topic": "0x95e0325a2d4f803db1237b0e454f7d9a09ec46941e478e3e98c510d8f1506031",
            "fourth_topic": null,
            "second_topic": null,
            "third_topic": null,
            "transaction_hash": "0xeaf751c7eb86b679b7138fac22c603fccb0ca397bccce5a74e5372da7ea12c22"
          }
        ]
      }
    }
    ```
    """
    field :logs, :paginate_logs do
      arg(:input, non_null(:log_input))

      middleware(MDowncase, [
        :first_topic,
        :second_topic,
        :third_topic,
        :fourth_topic
      ])

      resolve(&Resolvers.Log.logs/3)
    end
  end

  object :paginate_logs do
    field :entries, list_of(:log)
    field :metadata, :paginate_metadata
  end

  object :log do
    field :transaction_hash, :hash_full, description: "Layer2 transaction."
    field :data, :string, description: "Log data."
    field :first_topic, :string, description: "Log first topic."
    field :second_topic, :string, description: "Log second topic."
    field :third_topic, :string, description: "Log third topic."
    field :fourth_topic, :string, description: "Log fourth topic."
    field :index, :integer, description: "Log index."
    field :block_number, :integer, description: "Layer2 block number."
    field :address_hash, :hash_address, description: "Contract address."
    field :block_hash, :hash_full, description: " Layer2 block hash."

    field :udt, :udt do
      resolve(&Resolvers.Log.udt/3)
    end

    field :smart_contract, :smart_contract do
      resolve(&Resolvers.Log.smart_contract/3)
    end
  end

  enum :logs_sorter do
    value(:transaction_hash)
    value(:index)
    value(:block_number)
  end

  input_object :logs_sorter_input do
    field :sort_type, :sort_type
    field :sort_value, :logs_sorter
  end

  input_object :log_input do
    field :transaction_hash, :hash_full
    field :first_topic, :string
    field :second_topic, :string
    field :third_topic, :string
    field :fourth_topic, :string
    field :address_hash, :hash_address

    field :sorter, list_of(:logs_sorter_input),
      default_value: [
        %{sort_type: :asc, sort_value: :transaction_hash},
        %{sort_type: :asc, sort_value: :index}
      ]

    import_fields(:block_range_input)
    import_fields(:paginate_input)
  end
end
