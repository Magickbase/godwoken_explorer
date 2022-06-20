defmodule GodwokenExplorer.Graphql.Types.Account do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :account_querys do
    @desc """
    function: get account by account addresses

    request-example:
    query {
      account(input: {address: "0x59b670e9fa9d0a427751af201d676719a970857b"}){
        type
        eth_address
      }
    }

    result-example:
    {
      "data": {
        "account": {
          "eth_address": "0x59b670e9fa9d0a427751af201d676719a970857b",
          "type": "POLYJUICE_CONTRACT"
        }
      }
    }

    request-example-1:
    query {
      account(input: {script_hash: "0x08c9937e412e135928fd6dec7255965ddd7df4d5a163564b60895100bb3b2f9e"}){
        type
        eth_address
        script_hash
      }
    }

    result-example:
    {
      "data": {
        "account": {
          "eth_address": null,
          "script_hash": "0x08c9937e412e135928fd6dec7255965ddd7df4d5a163564b60895100bb3b2f9e",
          "type": "ETH_ADDR_REG"
        }
      }
    }

    request-example-2:
    query {
      account(input: {address: "0xcae7ac7ea158326cc16b4a5f1668924966419455"}){
        type
        eth_address
        account_udts {
          id
          balance
          udt {
            id
            name
            decimal
          }
        }
      }
    }

    result-example-2:
    {
      "data": {
        "account": {
          "account_udts": [
            {
              "balance": "2599999999999999997122",
              "id": 527,
              "udt": {
                "decimal": null,
                "id": "80",
                "name": null
              }
            },
            {
              "balance": "2299999999989999656533",
              "id": 524,
              "udt": {
                "decimal": null,
                "id": "1",
                "name": null
              }
            }
          ],
          "eth_address": "0xcae7ac7ea158326cc16b4a5f1668924966419455",
          "type": "ETH_USER"
        }
      }
    }

    request-example-3:
    query {
      account(
        input: {
          script_hash: "0x946d08cc356c4fe13bc49929f1f709611fe0a2aaa336efb579dad4ca197d1551"
        }
      ) {
        type
        eth_address
        script_hash
        script
      }
    }


    {
      "data": {
        "account": {
          "eth_address": null,
          "script": {
            "account_merkle_state": {
              "account_count": 33776,
              "account_merkle_root": "0x2a3fc6ea37bf17b717630f1f8f02a18ef9e96edf7461d6f8df5d4e115f6eb9dd"
            },
            "args": "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8",
            "block_merkle_state": {
              "block_count": 103767,
              "block_merkle_root": "0xb6b6d9befa9012b750b666df8522e8d164b222924028a4b91d0ba4eb2f1578cb"
            },
            "code_hash": "0x37b25df86ca495856af98dff506e49f2380d673b0874e13d29f7197712d735e8",
            "hash_type": "type",
            "last_finalized_block_number": 103666,
            "reverted_block_root": "0000000000000000000000000000000000000000000000000000000000000000",
            "status": "running"
          },
          "script_hash": "0x946d08cc356c4fe13bc49929f1f709611fe0a2aaa336efb579dad4ca197d1551",
          "type": "META_CONTRACT"
        }
      }
    }

    request-example-4:
    query {
      account(
        input: {
          script_hash: "0x64050af0d25c38ddf9455b8108654f7c5cc30fe6d871a303d83b1020edddd7a7"
        }
      ) {
        type
        script_hash
        script
        udt {
          id
          name
          decimal
        }
      }
    }

    {
      "data": {
        "account": {
          "script": {
            "args": "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8dac0c53c572f451e56c092fdb520aec82f5f4bf8a5c02e1c4843f40c15f84c55",
            "code_hash": "0xb6176a6170ea33f8468d61f934c45c57d29cdc775bcd3ecaaec183f04b9f33d9",
            "hash_type": "type"
          },
          "script_hash": "0x64050af0d25c38ddf9455b8108654f7c5cc30fe6d871a303d83b1020edddd7a7",
          "type": "UDT",
          "udt": {
            "decimal": 18,
            "id": "80",
            "name": "USD Coin"
          }
        }
      }
    }

    request-example-5:
    query {
      account(
        input: {
          script_hash: "0x829cc5785a4d8ac642ede32cb3cb5cb9dc389d5892f2fc2afc760691445be194"
        }
      ) {
        type
        eth_address
        script_hash
        script
      }
    }

    {
      "data": {
        "account": {
          "eth_address": "0x2f760c8f8656bde4995f26b8963e2dd801000000",
          "script": {
            "args": "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd801000000",
            "code_hash": "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
            "hash_type": "type"
          },
          "script_hash": "0x829cc5785a4d8ac642ede32cb3cb5cb9dc389d5892f2fc2afc760691445be194",
          "type": "POLYJUICE_CREATOR"
        }
      }
    }

    request-example-6:
    query {
      account(
        input: {
          script_hash: "0x08c9937e412e135928fd6dec7255965ddd7df4d5a163564b60895100bb3b2f9e"
        }
      ) {
        type
        eth_address
        script_hash
        script
      }
    }

    {
      "data": {
        "account": {
          "eth_address": null,
          "script": {
            "args": "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8",
            "code_hash": "0xa30dcbb83ebe571f49122d8d1ce4537679ebf511261c8ffaaa6679bf9fdea3a4",
            "hash_type": "type"
          },
          "script_hash": "0x08c9937e412e135928fd6dec7255965ddd7df4d5a163564b60895100bb3b2f9e",
          "type": "ETH_ADDR_REG"
        }
      }
    }

    request-example-7:
    query {
      account(
        input: {
          script_hash: "0x9b55204439c78d3b9cbcc62c03f31e47c8457fd39ca9a9eb805b364b45c26c38"
        }
      ) {
        type
        eth_address
        script
        script_hash
        smart_contract {
          id
          account_id
          name
        }
      }
    }

    {
      "data": {
        "account": {
          "eth_address": "0x2503a1a79a443f3961ee96a8c5ec513638129614",
          "script": {
            "args": "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8040000002503a1a79a443f3961ee96a8c5ec513638129614",
            "code_hash": "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
            "hash_type": "type"
          },
          "script_hash": "0x9b55204439c78d3b9cbcc62c03f31e47c8457fd39ca9a9eb805b364b45c26c38",
          "smart_contract": {
            "account_id": "6841",
            "id": 1,
            "name": "Test"
          },
          "type": "POLYJUICE_CONTRACT"
        }
      }
    }
    """
    field :account, :account do
      arg(:input, non_null(:account_input))
      resolve(&Resolvers.Account.account/3)
    end
  end

  object :account_mutations do
  end

  object :account do
    field :id, :integer
    field :eth_address, :hash_full
    field :script_hash, :hash_address
    field :registry_address, :string
    field :script, :json
    field :nonce, :integer
    field :transaction_count, :integer
    field :token_transfer_count, :integer
    field :contract_code, :string
    field :type, :account_type

    field :udt, :udt do
      resolve(&Resolvers.Account.udt/3)
    end

    field :account_current_udts, list_of(:account_current_udt) do
      arg(:input, :account_child_udts_input,
        default_value: %{page: 1, page_size: 20, sort_type: :desc}
      )

      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.Account.account_current_udts/3)
    end

    field :account_current_bridged_udts, list_of(:account_current_bridged_udt) do
      arg(:input, :account_child_udts_input,
        default_value: %{page: 1, page_size: 20, sort_type: :desc}
      )

      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.Account.account_current_bridged_udts/3)
    end

    field :smart_contract, :smart_contract do
      resolve(&Resolvers.Account.smart_contract/3)
    end
  end

  enum :account_type do
    value(:meta_contract)
    value(:udt)
    value(:eth_user)
    value(:polyjuice_creator)
    value(:polyjuice_contract)
    value(:eth_addr_reg)
  end

  input_object :account_input do
    @desc """
    address: account address(eth_address)
    example: "0x59b670e9fa9d0a427751af201d676719a970857b"

    script_hash: script hash with hash_full type
    example: "0x08c9937e412e135928fd6dec7255965ddd7df4d5a163564b60895100bb3b2f9e"
    """
    field :address, :hash_address
    field :script_hash, :hash_full
  end

  input_object :account_child_udts_input do
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
  end
end
