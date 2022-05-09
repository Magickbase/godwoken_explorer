defmodule GodwokenExplorer.Graphql.Types.Log do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.Downcase, as: MDowncase
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :log_querys do
    @desc """
    function: get list of logs by filter or conditions

    request-example:
    query {
      logs(input: {first_topic: "0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0",end_block_number: 346283, page: 1, page_size: 1}) {
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

    result-example:
    {
      "data": {
        "logs": [
          {
            "address_hash": "0x2406a7233d72540291ff0627c397b26fd73dc3d9",
            "block_number": 346283,
            "data": "0x0000000000000000000000000000000000000000000000000000000000000000",
            "first_topic": "0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0",
            "fourth_topic": null,
            "second_topic": "0x0000000000000000000000000000000000000000000000000000000000000000",
            "third_topic": "0x000000000000000000000000b3a91e71f67c29ae9ed5e164e8a1daa4c9e71361",
            "transaction_hash": "0x835eadb22bd55661717b0829b6bb29fb461facdbdc21f803752f9e7383577581"
          }
        ]
      }
    }
    """
    field :logs, list_of(:log) do
      arg(:input, non_null(:log_input))

      middleware(MDowncase, [
        :transaction_hash,
        :first_topic,
        :second_topic,
        :third_topic,
        :fourth_topic,
        :address_hash
      ])

      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.Log.logs/3)
    end
  end

  object :log do
    field :transaction_hash, :string
    field :data, :string
    field :first_topic, :string
    field :second_topic, :string
    field :third_topic, :string
    field :fourth_topic, :string
    field :index, :integer
    field :block_number, :integer
    field :address_hash, :string
    field :block_hash, :string
  end

  input_object :log_input do
    field :transaction_hash, :string
    field :first_topic, :string
    field :second_topic, :string
    field :third_topic, :string
    field :fourth_topic, :string
    field :address_hash, :string
    import_fields(:block_range_input)
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
  end
end
