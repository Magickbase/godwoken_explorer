defmodule GodwokenExplorer.Graphql.Types.AccountUDT do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.EIP55, as: MEIP55
  alias GodwokenExplorer.Graphql.Middleware.Downcase, as: MDowncase
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :account_udt_querys do
    @desc """
    function: get list of account udt by account addresses

    request-result-example:
    query {
      account_udts(input: {address_hashes: ["0x451bae98fe4daf99d45d3399b5acee2e55654c76"]}) {
        address_hash
        balance
        udt{
          id
          type
          name
          bridge_account_id
        }
      }
    }

    {
      "data": {
        "account_udts": [
          {
            "address_hash": "0x451bae98fe4daf99d45d3399b5acee2e55654c76",
            "balance": "2601000000000000000000",
            "udt": {
              "bridge_account_id": null,
              "id": "1",
              "name": null,
              "type": "BRIDGE"
            }
          }
        ]
      }
    }

    request-result-example-1:
    query {
      account_udts(
        input: {
          script_hashes: [ "0x20b9546f0fe576733a4b7caf1c74465e5059f4036591963f06266329c8d2c859"
          ]
        }
      ) {
        address_hash
        balance
        udt {
          id
          type
          name
          bridge_account_id
        }
      }
    }

    {
      "data": {
        "account_udts": [
          {
            "address_hash": "0x39d260d641b576a77aa8862a9f617d183b9826f6",
            "balance": "900000000000000000000",
            "udt": {
              "bridge_account_id": null,
              "id": "1",
              "name": null,
              "type": "BRIDGE"
            }
          }
        ]
      }
    }
    """
    field :account_udts, list_of(:account_udt) do
      arg(:input, non_null(:account_udts_input))
      middleware(MEIP55, [:address_hashes, :token_contract_address_hash])
      middleware(MDowncase, [:address_hashes, :token_contract_address_hash])
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.AccountUDT.account_udts/3)
    end

    @desc """
    function: get list of account ckbs by account addresses

    request-result-example:
    query {
      account_ckbs(input: {address_hashes: ["0x451bae98fe4daf99d45d3399b5acee2e55654c76"]}){
        address_hash
        balance
      }
    }

    {
      "data": {
        "account_ckbs": [
          {
            "address_hash": "0x451bae98fe4daf99d45d3399b5acee2e55654c76",
            "balance": "2601000000000000000000"
          }
        ]
      }
    }

    request-result-example-1:
    query {
      account_ckbs(
        input: {
          script_hashes: [   "0x20b9546f0fe576733a4b7caf1c74465e5059f4036591963f06266329c8d2c859"
          ]
        }
      ) {
        address_hash
        balance
      }
    }

    {
      "data": {
        "account_ckbs": [
          {
            "address_hash": "0x39d260d641b576a77aa8862a9f617d183b9826f6",
            "balance": "900000000000000000000"
          }
        ]
      }
    }
    """
    field :account_ckbs, list_of(:account_ckb) do
      arg(:input, non_null(:account_ckbs_input))
      middleware(MEIP55, [:address_hashes])
      middleware(MDowncase, [:address_hashes])
      resolve(&Resolvers.AccountUDT.account_ckbs/3)
    end

    @desc """
    function: get list account udts by smart contract address which sort of balance

    request-example:
    query {
      account_udts_by_contract_address(input: {token_contract_address_hash: "0xbf1f27daea43849b67f839fd101569daaa321e2c", page_size: 2}){
        address_hash
        balance
        udt {
          type
    	    name
        }
      }
    }

    result-example:
    {
      "data": {
        "account_udts_by_contract_address": [
          {
            "address_hash": "0x68f5cea51fa6fcfdcc10f6cddcafa13bf6717436",
            "balance": "3711221022882427",
            "udt": {
              "name": "Nervos Token",
              "type": "BRIDGE"
            }
          },
          {
            "address_hash": "0x7c12cbcbc3703bff1230434f792d84d70d47bb6f",
            "balance": "1075120930414037",
            "udt": {
              "name": "Nervos Token",
              "type": "BRIDGE"
            }
          }
        ]
      }
    }
    """
    field :account_udts_by_contract_address, list_of(:account_udt) do
      arg(:input, non_null(:account_udt_contract_address_input))
      middleware(MEIP55, [:token_contract_address_hash])
      middleware(MDowncase, [:token_contract_address_hash])
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.AccountUDT.account_udts_by_contract_address/3)
    end
  end

  object :account_ckb do
    field :address_hash, :string
    field :balance, :bigint
  end

  object :account_udt do
    field :id, :integer
    field :balance, :bigint
    field :address_hash, :string
    field :token_contract_address_hash, :string

    field :udt, :udt do
      resolve(&Resolvers.AccountUDT.udt/3)
    end

    field :account, :account do
      resolve(&Resolvers.AccountUDT.account/3)
    end
  end

  input_object :account_ckbs_input do
    field :address_hashes, list_of(:string), default_value: []
    field :script_hashes, list_of(:string), default_value: []
  end

  input_object :account_udts_input do
    import_fields(:page_and_size_input)

    @desc """
    argument: the list of account eth address
    example: ["0x15ca4f2165ff0e798d9c7434010eaacc4d768d85"]
    """
    field :address_hashes, list_of(:string), default_value: []

    @desc """
    argument: the list of account script hash
    example: ["0x08c9937e412e135928fd6dec7255965ddd7df4d5a163564b60895100bb3b2f9e"]
    """
    field :script_hashes, list_of(:string), default_value: []

    @desc """
    argument: the address of smart contract which supply udts
    example: "0xbf1f27daea43849b67f839fd101569daaa321e2c"
    """
    field :token_contract_address_hash, :string
  end

  input_object :account_udt_contract_address_input do
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
    field :token_contract_address_hash, non_null(:string)
  end
end
