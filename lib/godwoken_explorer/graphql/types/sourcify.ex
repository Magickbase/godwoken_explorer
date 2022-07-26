defmodule GodwokenExplorer.Graphql.Types.Sourcify do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :sourcify_querys do
    @desc """
    check by addresses example:
    query {
      sourcify_check_by_addresses(
        input: { addresses: ["0x7A4a65Db21864384d2D21a60367d7Fd5c86F8Fba"] }
      ) {
        address
    status
        chain_ids
      }
    }

    {
      "data": {
        "sourcify_check_by_addresses": [
          {
            "address": "0x7a4a65db21864384d2d21a60367d7fd5c86f8fba",
            "chain_ids": [
              "71401"
            ],
            "status": "perfect"
          }
        ]
      }
    }
    """
    field :sourcify_check_by_addresses, list_of(:sourcify_check_by_addresses) do
      arg(:input, non_null(:sourcify_check_by_addresses_input))
      resolve(&Resolvers.Sourcify.check_by_addresses/3)
    end
  end

  object :sourcify_mutations do
    @desc """
    example:
    mutation {
      verify_and_update_from_sourcify(
        input: { address: "0x7A4a65Db21864384d2D21a60367d7Fd5c86F8Fba" }
      ) {
        id
        account_id
        # contract_source_code
        # abi
				compiler_version
        deployment_tx_hash
				name
      }
    }

    {
      "data": {
        "verify_and_update_from_sourcify": {
          "account_id": "43012",
          "compiler_version": "v0.8.9+commit.e5eed63a",
          "deployment_tx_hash": "0x505e25885828c847102af40848ba9cdaf7974d2046e7949ed46e2024494f33cd",
          "id": 4,
          "name": "Bridge"
        }
      }
    }
    """
    field :verify_and_update_from_sourcify, :smart_contract do
      arg(:input, non_null(:verify_and_update_from_sourcify_input))
      resolve(&Resolvers.Sourcify.verify_and_publish/3)
    end
  end

  object :sourcify_check_by_addresses do
    field :address, :hash_address
    field :status, :string
    field :chain_ids, list_of(:string)
  end

  object :verify_and_update_from_sourcify do
    field :address, :hash_address
  end

  input_object :sourcify_check_by_addresses_input do
    field :addresses, non_null(list_of(:hash_address))
  end

  input_object :verify_and_update_from_sourcify_input do
    field :address, non_null(:hash_address)
  end
end
