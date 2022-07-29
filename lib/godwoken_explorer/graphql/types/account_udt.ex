defmodule GodwokenExplorer.Graphql.Types.AccountUDT do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :account_udt_querys do
    @desc """
    request-result-example:
    query {
      account_current_udts(
        input: {
          address_hashes: ["0xC6A44E4D2216A98B3A5086A64A33D94FBCC8FEC3"]
          token_contract_address_hash: "0xbb30e8691f6ffd5b4c0b2f73d17847e1e289ea80"
        }
      ) {
        block_number
        id
        token_contract_address_hash
        value
        value_fetched_at
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }


    {
      "data": {
        "account_current_udts": []
      }
    }
    """
    field :account_current_udts, list_of(:account_current_udt) do
      arg(:input, non_null(:account_current_udts_input))
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.AccountUDT.account_current_udts/3)
    end

    @desc """
    request-result-example:
    query {
      account_current_bridged_udts(
        input: {
          address_hashes: ["0x715AB282B873B79A7BE8B0E8C13C4E8966A52040"]
          udt_script_hash: "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
        }
      ) {
        block_number
        id
        udt_script_hash
        value
        value_fetched_at
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }

    {
      "data": {
        "account_current_bridged_udts": [
          {
            "account": {
              "eth_address": null,
              "id": 1,
              "script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
            },
            "block_number": null,
            "id": 1,
            "udt": {
              "bridge_account_id": null,
              "decimal": null,
              "id": "1",
              "name": null,
              "script_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
              "value": null
            },
            "udt_script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
            "value": "1165507481400061309833",
            "value_fetched_at": null
          }
        ]
      }
    }
    """
    field :account_current_bridged_udts, list_of(:account_current_bridged_udt) do
      arg(:input, non_null(:account_current_bridged_udts_input))
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.AccountUDT.account_current_bridged_udts/3)
    end

    @desc """
    request-result-example:
    query {
      account_ckbs(
        input: { address_hashes: ["0x715AB282B873B79A7BE8B0E8C13C4E8966A52040"] }
      ) {
        udt_script_hash
        value
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }

    {
      "data": {
        "account_ckbs": [
          {
            "account": {
              "eth_address": null,
              "id": 1,
              "script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
            },
            "udt": {
              "bridge_account_id": 375,
              "decimal": 18,
              "id": "1",
              "name": "pCKB",
              "script_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
              "value": null
            },
            "udt_script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
            "value": "1165507481400061309833"
          }
        ]
      }
    }
    """
    field :account_ckbs, list_of(:account_udt) do
      arg(:input, non_null(:account_ckbs_input))
      resolve(&Resolvers.AccountUDT.account_ckbs/3)
    end


    @desc """
    request-result-example:
    query {
      account_udts(
        input: {
          address_hashes: ["0x715AB282B873B79A7BE8B0E8C13C4E8966A52040"],

          udt_script_hash: "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
        }
      ) {
        udt_script_hash
        value
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }

    {
      "data": {
        "account_udts": [
          {
            "account": {
              "eth_address": null,
              "id": 1,
              "script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
            },
            "udt": {
              "bridge_account_id": 375,
              "decimal": 18,
              "id": "1",
              "name": "pCKB",
              "script_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
              "value": null
            },
            "udt_script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
            "value": "1165507481400061309833"
          }
        ]
      }
    }
    """
    field :account_udts, list_of(:account_udt) do
      arg(:input, non_null(:account_udts_input))
      resolve(&Resolvers.AccountUDT.account_udts/3)
    end

    @desc """
    request-result-example:
    query {
      account_udts_by_contract_address(
        input: {
          token_contract_address_hash: "0xD1556D3FE220B6EB816536AB448DE4E4EDC3E439"
          sort_type: ASC
          page_size: 1
        }
      ) {
        block_number
        id
        token_contract_address_hash
        value
        value_fetched_at
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }

    {
      "data": {
        "account_udts_by_contract_address": [
          {
            "account": {
              "eth_address": "0xd1556d3fe220b6eb816536ab448de4e4edc3e439",
              "id": 70,
              "script_hash": "0x66fb5a40e0bb9c62a68770b77393e2c5cc8428503025d9478550e99d0bed5138"
            },
            "block_number": 2857,
            "id": 5,
            "token_contract_address_hash": "0xd1556d3fe220b6eb816536ab448de4e4edc3e439",
            "udt": null,
            "value": "4",
            "value_fetched_at": "2022-06-01T06:03:53.730509Z"
          }
        ]
      }
    }
    """
    field :account_udts_by_contract_address, list_of(:account_current_udt) do
      arg(:input, non_null(:account_udts_by_contract_address_input))
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.AccountUDT.account_udts_by_contract_address/3)
    end

    @desc """
    request-result-example:
    query {
      account_bridged_udts_by_script_hash(
        input: {
          udt_script_hash: "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
          sort_type: ASC
          page_size: 1
        }
      ) {
        block_number
        id
        udt_script_hash
        value
        value_fetched_at
        udt {
          id
          name
          bridge_account_id
          script_hash
          decimal
          value
        }
        account {
          id
          eth_address
          script_hash
        }
      }
    }

    {
      "data": {
        "account_bridged_udts_by_script_hash": [
          {
            "account": {
              "eth_address": null,
              "id": 1,
              "script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
            },
            "block_number": 6135,
            "id": 49,
            "udt": {
              "bridge_account_id": null,
              "decimal": null,
              "id": "1",
              "name": null,
              "script_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
              "value": null
            },
            "udt_script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca",
            "value": "0",
            "value_fetched_at": null
          }
        ]
      }
    }
    """
    field :account_bridged_udts_by_script_hash, list_of(:account_current_bridged_udt) do
      arg(:input, non_null(:account_bridged_udts_by_script_hash_input))
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.AccountUDT.account_bridged_udts_by_script_hash/3)
    end
  end

  object :account_udt do
    field :value, :bigint
    field :address_hash, :hash_address
    field :token_contract_address_hash, :hash_address
    field :udt_script_hash, :hash_full

    field :udt, :udt do
      resolve(&Resolvers.AccountUDT.udt/3)
    end

    field :account, :account do
      resolve(&Resolvers.AccountUDT.account/3)
    end
  end

  object :account_current_udt do
    field :id, :integer
    field :value, :bigint
    field :value_fetched_at, :datetime
    field :block_number, :integer
    field :address_hash, :hash_address
    field :token_contract_address_hash, :hash_address

    field :udt, :udt do
      resolve(&Resolvers.AccountUDT.udt/3)
    end

    field :account, :account do
      resolve(&Resolvers.AccountUDT.account/3)
    end

    import_fields(:ecto_datetime)
  end

  object :account_current_bridged_udt do
    field :id, :integer
    field :value, :bigint
    field :value_fetched_at, :datetime
    field :layer1_block_number, :integer
    field :block_number, :integer
    field :address_hash, :hash_address
    field :udt_script_hash, :hash_full

    field :udt, :udt do
      resolve(&Resolvers.AccountUDT.udt/3)
    end

    field :account, :account do
      resolve(&Resolvers.AccountUDT.account/3)
    end

    import_fields(:ecto_datetime)
  end

  input_object :account_ckbs_input do
    field :address_hashes, list_of(:hash_address), default_value: []
    field :script_hashes, list_of(:hash_full), default_value: []
  end

  input_object :account_udts_input do
    field :address_hashes, list_of(:hash_address), default_value: []
    field :script_hashes, list_of(:hash_full), default_value: []
    field :token_contract_address_hash, :hash_address
    field :udt_script_hash, :hash_full
  end

  input_object :account_current_udts_input do
    import_fields(:page_and_size_input)

    @desc """
    argument: the list of account eth address
    example: ["0x15ca4f2165ff0e798d9c7434010eaacc4d768d85"]
    """
    field :address_hashes, list_of(:hash_address), default_value: []

    @desc """
    argument: the list of account script hash
    example: ["0x08c9937e412e135928fd6dec7255965ddd7df4d5a163564b60895100bb3b2f9e"]
    """
    field :script_hashes, list_of(:hash_full), default_value: []

    @desc """
    argument: the address of smart contract which supply udts
    example: "0xbf1f27daea43849b67f839fd101569daaa321e2c"
    """
    field :token_contract_address_hash, :hash_address
  end

  input_object :account_current_bridged_udts_input do
    import_fields(:page_and_size_input)

    @desc """
    argument: the list of account eth address
    example: ["0x15ca4f2165ff0e798d9c7434010eaacc4d768d85"]
    """
    field :address_hashes, list_of(:hash_address), default_value: []

    @desc """
    argument: the list of account script hash
    example: ["0x08c9937e412e135928fd6dec7255965ddd7df4d5a163564b60895100bb3b2f9e"]
    """
    field :script_hashes, list_of(:hash_address), default_value: []
    field :udt_script_hash, :hash_full
  end

  input_object :account_udts_by_contract_address_input do
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
    field :token_contract_address_hash, non_null(:hash_address)
  end

  input_object :account_bridged_udts_by_script_hash_input do
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
    field :udt_script_hash, non_null(:hash_full)
  end
end
