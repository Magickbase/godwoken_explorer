defmodule GodwokenExplorer.Graphql.Types.TokenApproval do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.NullFilter

  object :token_approval_querys do
    @desc """
    function: get list of token approvals by filter

    example:
    query {
      token_approvals(
        input: {
          address: "0x966b30e576a4d6731996748b48dd67c94ef29067"
          token_type: ERC20
          limit: 2

          sorter: [
            { sort_type: DESC, sort_value: BLOCK_NUMBER },
            { sort_type: DESC, sort_value: ID }
          ]
        }
      ) {
        entries {
          transaction_hash
          udt {
            id
            name
            eth_type
          }
          block {
            timestamp
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
        "token_approvals": {
          "entries": [
            {
              "block": {
                "timestamp": "2022-05-08T05:19:15.637000Z"
              },
              "transaction_hash": "0xa22dc752ce79bc923ea86d0135b39074c6fc56a7c10cb60879180bcfd81142c7",
              "udt": {
                "eth_type": "ERC20",
                "id": 22,
                "name": "testERC20"
              }
            }
          ],
          "metadata": {
            "after": "g3QAAAABZAAMYmxvY2tfbnVtYmVyYVk=",
            "before": null,
            "total_count": 6
          }
        }
      }
    }
    """
    field :token_approvals, :paginate_token_approvals do
      arg(:input, non_null(:token_approval_input), default_value: %{})
      middleware(NullFilter)
      resolve(&Resolvers.TokenApproval.token_approvals/3)
    end
  end

  object :paginate_token_approvals do
    field :entries, list_of(:token_approval)
    field :metadata, :paginate_metadata
  end

  object :token_approval do
    field :transaction_hash, :hash_full
    field :block_hash, :hash_full
    field :block_number, :integer
    field :token_owner_address_hash, :hash_address
    field :spender_address_hash, :string
    field :token_contract_address_hash, :hash_address
    field :data, :decimal
    field :approved, :boolean
    field :type, :approval_type

    field :block, :block do
      resolve(&Resolvers.TokenApproval.block/3)
    end

    field :udt, :udt do
      resolve(&Resolvers.TokenApproval.udt/3)
    end
  end

  enum :approval_type do
    value(:approval)
    value(:approval_all)
  end

  input_object :token_approval_input do
    field :address, :hash_address
    field :token_type, :token_type

    field :sorter, list_of(:token_approvals_sorter_input),
      default_value: [
        %{sort_type: :desc, sort_value: :block_number},
        %{sort_type: :desc, sort_value: :id}
      ]

    import_fields(:paginate_input)
  end

  enum :token_type do
    value(:erc20)
    value(:erc721)
    value(:erc1155)
  end

  enum :token_approvals_sorter do
    value(:block_number)
    value(:id)
  end

  input_object :token_approvals_sorter_input do
    field :sort_type, :sort_type
    field :sort_value, :token_approvals_sorter
  end
end
