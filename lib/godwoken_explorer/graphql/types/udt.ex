defmodule GodwokenExplorer.Graphql.Types.UDT do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :udt_querys do
    @desc """
    function: get udt by contract address

    contract address example:
    query {
      udt(
        input: { contract_address: "0x2275AFE815DE66BEABE7A2C03005537AB843AFB2" }
      ) {
        id
        name
        script_hash
        contract_address_hash
      }
    }

    {
      "data": {
        "udt": {
          "contract_address_hash": "0x2275afe815de66beabe7a2c03005537ab843afb2",
          "id": "36050",
          "name": "GodwokenToken on testnet_v1",
          "script_hash": null
        }
      }
    }

    id example:
    query {
      udt(
        input: {
          id: 36050
          contract_address: "0x2275AFE815DE66BEABE7A2C03005537AB843AFB2"
        }
      ) {
        id
        bridge_account_id
        name
        script_hash
        contract_address_hash
      }
    }


    {
      "data": {
        "udt": {
          "bridge_account_id": null,
          "contract_address_hash": "0x2275afe815de66beabe7a2c03005537ab843afb2",
          "id": "36050",
          "name": "GodwokenToken on testnet_v1",
          "script_hash": null
        }
      }
    }
    """
    field :udt, :udt do
      arg(:input, non_null(:udt_input))
      resolve(&Resolvers.UDT.udt/3)
    end

    @desc """
    function: get list of udts

    pagination-example:
    query {
      udts(
        input: {
          limit: 1
          after: "g3QAAAABZAACaWRhAQ=="
          sorter: [{ sort_type: ASC, sort_value: ID }]
        }
      ) {
        entries {
          id
          name
          type
          supply
          account {
            eth_address
            script_hash
          }
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "udts": {
          "entries": [
            {
              "account": {
                "eth_address": null,
                "script_hash": "0x64050af0d25c38ddf9455b8108654f7c5cc30fe6d871a303d83b1020edddd7a7"
              },
              "id": "80",
              "name": null,
              "supply": null,
              "type": "BRIDGE"
            }
          ],
          "metadata": {
            "after": "g3QAAAABZAACaWRhUA==",
            "before": "g3QAAAABZAACaWRhUA==",
            "total_count": 14
          }
        }
      }
    }


    fuzzy-name-example:
    fuzzy name use postgresql ilike keyword, pattern matching docs like: https://www.postgresql.org/docs/current/functions-matching.html#FUNCTIONS-LIKE

    query {
      udts(
        input: {
          limit: 1
          fuzzy_name: "%ckb%"
          sorter: [{ sort_type: ASC, sort_value: ID }]
        }
      ) {
        entries {
          id
          name
          type
          supply
          account {
            eth_address
            script_hash
          }
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "udts": {
          "entries": [
            {
              "account": {
                "eth_address": null,
                "script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
              },
              "id": "1",
              "name": "pCKB",
              "supply": "12800091655514882421855103",
              "type": "BRIDGE"
            }
          ],
          "metadata": {
            "after": null,
            "before": null,
            "total_count": 1
          }
        }
      }
    }

    sorter-example:
    query {
      udts(
        input: {
          limit: 3
          sorter: [{ sort_type: ASC, sort_value: SUPPLY }]
        }
      ) {
        entries {
          id
          name
          type
          supply
          account {
            eth_address
            script_hash
          }
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "udts": {
          "entries": [
            {
              "account": {
                "eth_address": "0x2503a1a79a443f3961ee96a8c5ec513638129614",
                "script_hash": "0x9b55204439c78d3b9cbcc62c03f31e47c8457fd39ca9a9eb805b364b45c26c38"
              },
              "id": "6841",
              "name": "test",
              "supply": "111",
              "type": "NATIVE"
            },
            {
              "account": {
                "eth_address": null,
                "script_hash": "0x3e1301e759261b676ce68d0d97936cd431a4af2a34072aa94e44655909765eb4"
              },
              "id": "6571",
              "name": "GodwokenToken on testnet_v1",
              "supply": "3247",
              "type": "BRIDGE"
            },
            {
              "account": {
                "eth_address": "0xd3ecf26a4a1e99c8717d7d8e365933fffa7d74d6",
                "script_hash": "0xb9150cbee429e205f9c956da7def16344232f50c851d9a5b0f7ef6f211c91cbf"
              },
              "id": "20021",
              "name": " My Hardhat Token",
              "supply": "100000000000000000000",
              "type": "NATIVE"
            }
          ],
          "metadata": {
            "after": "g3QAAAABZAAGc3VwcGx5dAAAAARkAApfX3N0cnVjdF9fZAAORWxpeGlyLkRlY2ltYWxkAARjb2VmbgkAAAAQYy1ex2sFZAADZXhwYQBkAARzaWduYQE=",
            "before": null,
            "total_count": 16
          }
        }
      }
    }

    sorter-example:
    query {
      udts(
        input: {
          limit: 3
          sorter: [{ sort_type: ASC, sort_value: NAME }]
        }
      ) {
        entries {
          id
          name
          type
          supply
          account {
            eth_address
            script_hash
          }
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "udts": {
          "entries": [
            {
              "account": {
                "eth_address": null,
                "script_hash": "0x3e1301e759261b676ce68d0d97936cd431a4af2a34072aa94e44655909765eb4"
              },
              "id": "6571",
              "name": "GodwokenToken on testnet_v1",
              "supply": "3247",
              "type": "BRIDGE"
            },
            {
              "account": {
                "eth_address": "0xd3ecf26a4a1e99c8717d7d8e365933fffa7d74d6",
                "script_hash": "0xb9150cbee429e205f9c956da7def16344232f50c851d9a5b0f7ef6f211c91cbf"
              },
              "id": "20021",
              "name": " My Hardhat Token",
              "supply": "100000000000000000000",
              "type": "NATIVE"
            },
            {
              "account": {
                "eth_address": null,
                "script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
              },
              "id": "1",
              "name": "pCKB",
              "supply": "12800091655514882421855103",
              "type": "BRIDGE"
            }
          ],
          "metadata": {
            "after": "g3QAAAABZAAEbmFtZW0AAAAEcENLQg==",
            "before": null,
            "total_count": 16
          }
        }
      }
    }

    holders example:
    query {
      udts(
        input: {
          limit: 1
          sorter: [
            { sort_type: DESC, sort_value: EX_HOLDERS_COUNT }
            { sort_type: ASC, sort_value: NAME }
          ]
        }
      ) {
        entries {
          id
          name
          holders_count
          type
          supply
          account {
            eth_address
            script_hash
          }
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "udts": {
          "entries": [
            {
              "account": {
                "eth_address": null,
                "script_hash": "0x595cc14e574a708dc70a320d2026f79374246ed4659261131cdda7dd5814b5ca"
              },
              "holders_count": 13563,
              "id": "1",
              "name": "pCKB",
              "supply": "13930369823571892421855103",
              "type": "BRIDGE"
            }
          ],
          "metadata": {
            "after": "g3QAAAABZAACaWRhAQ==",
            "before": null,
            "total_count": 14
          }
        }
      }
    }

    eth_type example:
    query {
      udts(input: {eth_type: ERC721, limit: 2}) {
        entries {
          id
          eth_type
          name
          icon
          symbol
          contract_address_hash
        }
      }
    }

    {
      "data": {
        "udts": {
          "entries": [
            {
              "contract_address_hash": "0x9fe6db42f85889a5f69f7e61fbaefe87943d9372",
              "eth_type": "ERC721",
              "icon": null,
              "id": 47928,
              "name": null,
              "symbol": null
            },
            {
              "contract_address_hash": "0x28eeb81d9c8f01b596258d7eea34bc5fa08a68f4",
              "eth_type": "ERC721",
              "icon": null,
              "id": 48085,
              "name": null,
              "symbol": null
            }
          ]
        }
      }
    }
    """
    field :udts, :paginate_udts do
      arg(:input, :udts_input, default_value: %{})
      resolve(&Resolvers.UDT.udts/3)
    end

    @desc """
    query {
      erc1155_user_token(
        input: {
          user_address: "0xc6e58fb4affb6ab8a392b7cc23cd3fef74517f6c"
          contract_address: "0xe6903e124e5bdae8784674eb625f1c212efc789e"
          token_id: 0
        }
      ) {
        value
        token_type
        token_id
        token_contract_address_hash
      }
    }

    {
      "data": {
        "erc1155_user_token": null
      }
    }
    """
    field :erc1155_user_token, :erc721_erc1155_user_token do
      arg(:input, non_null(:erc1155_user_token_input))
      resolve(&Resolvers.UDT.erc1155_user_token/3)
    end

    @desc """
    query {
      erc721_udts(
        input: { contract_address: "0x784cd3c52813098763c371df8fbe8ed27d2c1ebd" }
      ) {
        entries {
          id
          name
          contract_address_hash
          eth_type
          holders_count
          minted_count
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "erc721_udts": {
          "entries": [
            {
              "contract_address_hash": "0x784cd3c52813098763c371df8fbe8ed27d2c1ebd",
              "eth_type": "ERC721",
              "holders_count": 308,
              "id": 58460,
              "minted_count": 2000,
              "name": null
            }
          ],
          "metadata": {
            "after": null,
            "before": null,
            "total_count": 1
          }
        }
      }
    }

    query {
      erc721_udts(input: {limit: 1, sorter: [{sort_type: DESC, sort_value: EX_HOLDERS_COUNT}]}){
        entries {
          id
          name
          contract_address_hash
          eth_type
          holders_count
          minted_count
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "erc721_udts": {
          "entries": [
            {
              "contract_address_hash": "0x784cd3c52813098763c371df8fbe8ed27d2c1ebd",
              "eth_type": "ERC721",
              "holders_count": 308,
              "id": 58460,
              "minted_count": 2000,
              "name": null
            }
          ],
          "metadata": {
            "after": "g3QAAAAA",
            "before": null,
            "total_count": 3191
          }
        }
      }
    }
    """
    field :erc721_udts, :paginate_erc721_erc1155_udts do
      arg(:input, non_null(:erc721_erc1155_udts_input), default_value: %{})
      resolve(&Resolvers.UDT.erc721_udts/3)
    end

    @desc """
    query {
      erc1155_udts(input: {limit: 1, sorter: [{sort_type: DESC, sort_value: EX_HOLDERS_COUNT}]}){
        entries {
          id
          name
          contract_address_hash
          eth_type
          holders_count
          minted_count
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "erc1155_udts": {
          "entries": [
            {
              "contract_address_hash": "0xdb9e72a05c53a104c48fe343e9c58c66583df889",
              "eth_type": "ERC1155",
              "holders_count": 0,
              "id": 32343,
              "minted_count": 1,
              "name": null
            }
          ],
          "metadata": {
            "after": "g3QAAAAA",
            "before": null,
            "total_count": 524
          }
        }
      }
    }
    """
    field :erc1155_udts, :paginate_erc721_erc1155_udts do
      arg(:input, non_null(:erc721_erc1155_udts_input), default_value: %{})
      resolve(&Resolvers.UDT.erc1155_udts/3)
    end

    @desc """
    query {
      erc721_holders(
        input: {
          contract_address: "0x784cd3c52813098763c371df8fbe8ed27d2c1ebd"
          limit: 1
        }
      ) {
        entries {
          token_id
          address_hash
          token_contract_address_hash
          quantity
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "erc721_holders": {
          "entries": [
            {
              "address_hash": "0x0000000000ce6d8c1fba76f26d6cc5db71432710",
              "quantity": 1,
              "token_contract_address_hash": "0x784cd3c52813098763c371df8fbe8ed27d2c1ebd",
              "token_id": "593"
            }
          ],
          "metadata": {
            "after": "g3QAAAABZAAIcXVhbnRpdHlhAQ==",
            "before": null,
            "total_count": 2000
          }
        }
      }
    }
    """
    field :erc721_holders, :paginate_erc721_erc1155_holders do
      arg(:input, non_null(:erc721_erc1155_holders_input))
      resolve(&Resolvers.UDT.erc721_holders/3)
    end

    @desc """
    query {
      erc1155_holders(
        input: {
          contract_address: "0xe6903e124e5bdae8784674eb625f1c212efc789e"
          limit: 1
        }
      ) {
        entries {
          token_id
          address_hash
          token_contract_address_hash
          quantity
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    {
      "data": {
        "erc1155_holders": {
          "entries": [],
          "metadata": {
            "after": null,
            "before": null,
            "total_count": 0
          }
        }
      }
    }
    """
    field :erc1155_holders, :paginate_erc721_erc1155_holders do
      arg(:input, non_null(:erc721_erc1155_holders_input))
      resolve(&Resolvers.UDT.erc1155_holders/3)
    end

    @desc """
    query {
      user_erc721_assets(
        input: {
          user_address: "0x0000000000ce6d8c1fba76f26d6cc5db71432710"
          limit: 1
        }
      ) {
        entries {
          token_id
          address_hash
          token_contract_address_hash
          value
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "user_erc721_assets": {
          "entries": [
            {
              "address_hash": "0x0000000000ce6d8c1fba76f26d6cc5db71432710",
              "token_contract_address_hash": "0x784cd3c52813098763c371df8fbe8ed27d2c1ebd",
              "token_id": "641",
              "value": "4"
            }
          ],
          "metadata": {
            "after": "g3QAAAACZAAMYmxvY2tfbnVtYmVyYgAE5cVkABB2YWx1ZV9mZXRjaGVkX2F0dAAAAA1kAApfX3N0cnVjdF9fZAAPRWxpeGlyLkRhdGVUaW1lZAAIY2FsZW5kYXJkABNFbGl4aXIuQ2FsZW5kYXIuSVNPZAADZGF5YR9kAARob3VyYRBkAAttaWNyb3NlY29uZGgCYgAEVUxhBmQABm1pbnV0ZWEUZAAFbW9udGhhCGQABnNlY29uZGEcZAAKc3RkX29mZnNldGEAZAAJdGltZV96b25lbQAAAAdFdGMvVVRDZAAKdXRjX29mZnNldGEAZAAEeWVhcmIAAAfmZAAJem9uZV9hYmJybQAAAANVVEM=",
            "before": null,
            "total_count": 4
          }
        }
      }
    }
    """
    field :user_erc721_assets, :paginate_user_erc721_erc1155_assets do
      arg(:input, non_null(:user_erc721_erc1155_assets_input))
      resolve(&Resolvers.UDT.user_erc721_assets/3)
    end

    @desc """
    query {
      user_erc1155_assets(
        input: {
          user_address: "0xc6e58fb4affb6ab8a392b7cc23cd3fef74517f6c"
          limit: 1
        }
      ) {
        entries {
          token_id
          address_hash
          token_contract_address_hash
          value
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "user_erc1155_assets": {
          "entries": [],
          "metadata": {
            "after": null,
            "before": null,
            "total_count": 0
          }
        }
      }
    }
    """
    field :user_erc1155_assets, :paginate_user_erc721_erc1155_assets do
      arg(:input, non_null(:user_erc721_erc1155_assets_input))
      resolve(&Resolvers.UDT.user_erc1155_assets/3)
    end

    @desc """
    query {
      erc721_erc1155_inventory(
        input: {
          contract_address: "0x784cd3c52813098763c371df8fbe8ed27d2c1ebd"
          limit: 1
        }
      ) {
        entries {
          token_id
          address_hash
          token_contract_address_hash
          value
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "erc721_erc1155_inventory": {
          "entries": [
            {
              "address_hash": "0x7ec331e53da2ad677a7636b2da07d8dbea427ab7",
              "token_contract_address_hash": "0x784cd3c52813098763c371df8fbe8ed27d2c1ebd",
              "token_id": "2000",
              "value": "1"
            }
          ],
          "metadata": {
            "after": "g3QAAAACZAACaWRiABXtp2QACHRva2VuX2lkdAAAAARkAApfX3N0cnVjdF9fZAAORWxpeGlyLkRlY2ltYWxkAARjb2VmYgAAB9BkAANleHBhAGQABHNpZ25hAQ==",
            "before": null,
            "total_count": 2000
          }
        }
      }
    }

    query {
      erc721_erc1155_inventory(
        input: {
          contract_address: "0xe6903e124e5bdae8784674eb625f1c212efc789e"
          token_id: 0
          limit: 1
        }
      ) {
        entries {
          token_id
          address_hash
          token_contract_address_hash
          value
        }
        metadata {
          total_count
          after
          before
        }
      }
    }

    {
      "data": {
        "erc721_erc1155_inventory": {
          "entries": [],
          "metadata": {
            "after": null,
            "before": null,
            "total_count": 0
          }
        }
      }
    }
    """
    field :erc721_erc1155_inventory, :paginate_erc721_erc1155_inventory do
      arg(:input, non_null(:erc721_erc1155_inventory_input))
      resolve(&Resolvers.UDT.erc721_erc1155_inventory/3)
    end
  end

  object :paginate_udts do
    field(:entries, list_of(:udt))
    field(:metadata, :paginate_metadata)
  end

  object :paginate_erc721_erc1155_udts do
    field(:entries, list_of(:erc721_erc1155_udt))
    field(:metadata, :paginate_metadata)
  end

  object :paginate_erc721_erc1155_inventory do
    field(:entries, list_of(:erc721_erc1155_user_token))
    field(:metadata, :paginate_metadata)
  end

  object :paginate_erc721_erc1155_holders do
    field(:entries, list_of(:erc721_erc1155_holder_item))
    field(:metadata, :paginate_metadata)
  end

  object :paginate_user_erc721_erc1155_assets do
    field(:entries, list_of(:erc721_erc1155_user_token))
    field(:metadata, :paginate_metadata)
  end

  object :erc721_erc1155_holder_item do
    field(:address_hash, :hash_address)
    field(:token_contract_address_hash, :hash_address)
    field(:token_id, :decimal)
    field(:token_type, :eth_type)
    field(:quantity, :integer)
  end

  object :erc721_erc1155_user_token do
    field(:address_hash, :hash_address)
    field(:token_contract_address_hash, :hash_address)
    field(:token_id, :decimal)
    field(:token_type, :eth_type)
    field(:value, :decimal)

    field :udt, :erc721_erc1155_udt do
      resolve(&Resolvers.UDT.erc721_erc1155_udt/3)
    end
  end

  object :erc721_holder do
    field(:address_hash, :hash_address)
    field(:quantity, :decimal)
  end

  object :erc721_erc1155_udt do
    field(:id, :integer)
    field(:name, :string)
    field(:symbol, :string)
    field(:icon, :string)
    field(:contract_address_hash, :hash_address)
    field(:eth_type, :eth_type)

    field :account, :account do
      resolve(&Resolvers.UDT.account/3)
    end

    field(:description, :string)
    field(:official_site, :string)

    field :holders_count, :integer do
      resolve(&Resolvers.UDT.holders_count/3)
    end

    field :minted_count, :integer do
      resolve(&Resolvers.UDT.minted_count/3)
    end
  end

  object :udt do
    field(:id, :integer)
    field(:decimal, :integer)
    field(:name, :string)
    field(:symbol, :string)
    field(:icon, :string)
    field(:supply, :decimal)
    field(:type_script, :json)
    field(:script_hash, :hash_full)
    field(:description, :string)
    field(:official_site, :string)
    field(:value, :decimal)
    field(:price, :decimal)
    field(:bridge_account_id, :integer)
    field(:contract_address_hash, :hash_address)
    field(:type, :udt_type)
    field(:eth_type, :eth_type)

    field :account, :account do
      resolve(&Resolvers.UDT.account/3)
    end

    field :holders_count, :integer do
      resolve(&Resolvers.UDT.holders_count/3)
    end

    field :minted_count, :integer do
      resolve(&Resolvers.UDT.minted_count/3)
    end
  end

  enum :eth_type do
    value(:erc20)
    value(:erc721)
    value(:erc1155)
  end

  enum :udt_type do
    value(:bridge)
    value(:native)
  end

  enum :udts_sorter do
    value(:id)
    value(:name)
    value(:supply)
    value(:ex_holders_count)
  end

  input_object :udt_input do
    field(:id, :integer)
    field(:bridge_account_id, :integer)
    field(:contract_address, :hash_address)
  end

  input_object :user_erc721_erc1155_assets_input do
    field(:user_address, non_null(:hash_address))
    import_fields(:paginate_input)
  end

  input_object :erc721_erc1155_udts_input do
    field(:fuzzy_name, :string)
    field(:contract_address, :hash_address)

    field(:sorter, list_of(:udts_sorter_input),
      default_value: [%{sort_type: :asc, sort_value: :name}]
    )

    import_fields(:paginate_input)
  end

  input_object :erc721_erc1155_holders_input do
    field(:contract_address, non_null(:hash_address))
    import_fields(:paginate_input)
  end

  input_object :erc1155_user_token_input do
    field(:user_address, non_null(:hash_address))
    field(:contract_address, non_null(:hash_address))
    field(:token_id, non_null(:decimal))
  end

  input_object :erc721_erc1155_inventory_input do
    field(:contract_address, non_null(:hash_address))
    field(:token_id, :decimal)
    import_fields(:paginate_input)
  end

  input_object :udts_input do
    field(:type, :udt_type)
    field(:eth_type, :eth_type)
    import_fields(:erc721_erc1155_udts_input)
  end

  input_object :udts_sorter_input do
    field(:sort_type, :sort_type)
    field(:sort_value, :udts_sorter)
  end
end
