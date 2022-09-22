defmodule GodwokenExplorer.Graphql.Types.Log do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.Downcase, as: MDowncase
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

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
    field :logs, list_of(:log) do
      arg(:input, non_null(:log_input))

      middleware(MDowncase, [
        :first_topic,
        :second_topic,
        :third_topic,
        :fourth_topic
      ])

      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.Log.logs/3)
    end
  end

  object :log do
    field :transaction_hash, :hash_full
    field :data, :string
    field :first_topic, :string
    field :second_topic, :string
    field :third_topic, :string
    field :fourth_topic, :string
    field :index, :integer
    field :block_number, :integer
    field :address_hash, :hash_address
    field :block_hash, :hash_full
  end

  input_object :log_input do
    field :transaction_hash, :hash_full
    field :first_topic, :string
    field :second_topic, :string
    field :third_topic, :string
    field :fourth_topic, :string
    field :address_hash, :hash_address
    import_fields(:block_range_input)
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
  end
end
