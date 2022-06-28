defmodule GodwokenExplorer.Graphql.Types.UDT do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :udt_querys do
    @desc """
    function: get udt by contract address

    request-example:
    query {
      udt(input: {script_hash: "0x64050AF0D25C38DDF9455B8108654F7C5CC30FE6D871A303D83B1020EDDDD7A7"}){
        id
        name
        type
        supply
        account{
          eth_address
        }
      }
    }

    result-example:
    {
      "data": {
        "udt": {
          "account": {
            "eth_address": null
          },
          "id": "80",
          "name": null,
          "supply": null,
          "type": "BRIDGE"
        }
      }
    }
    """
    field :udt, :udt do
      arg(:input, non_null(:smart_contract_input))
      resolve(&Resolvers.UDT.udt/3)
    end

    @desc """
    function: get udt by contract address

    request-example:
    query {
      get_udt_by_account_id(input: {account_id: 80}){
        id
        name
        type
        supply
        account{
          eth_address
        }
      }
    }

    {
      "data": {
        "get_udt_by_account_id": {
          "account": {
            "eth_address": null
          },
          "id": "80",
          "name": "USD Coin",
          "supply": "9999999999",
          "type": "BRIDGE"
        }
      }
    }
    """
    field :get_udt_by_account_id, :udt do
      arg(:input, non_null(:account_id_input))
      resolve(&Resolvers.UDT.get_udt_by_account_id/3)
    end

    @desc """
    function: get list of udts

    request-example:
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



    result-example:
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
    """
    field :udts, :paginate_udts do
      arg(:input, :udts_input, default_value: %{})
      resolve(&Resolvers.UDT.udts/3)
    end
  end

  object :paginate_udts do
    field :entries, list_of(:udt)
    field :metadata, :paginate_metadata
  end

  object :udt do
    field :id, :string
    field :decimal, :integer
    field :name, :string
    field :symbol, :string
    field :icon, :string
    field :supply, :decimal
    field :type_script, :json
    field :script_hash, :hash_full
    field :description, :string
    field :official_site, :string
    field :value, :decimal
    field :price, :decimal
    field :bridge_account_id, :integer
    field :type, :udt_type

    field :account, :account do
      resolve(&Resolvers.UDT.account/3)
    end
  end

  enum :udt_type do
    value(:bridge)
    value(:native)
  end

  enum :udts_sorter do
    value(:id)
    value(:name)
    value(:supply)
    # value(:holders)
  end

  input_object :account_id_input do
    field :account_id, :integer
  end

  input_object :udts_input do
    field :type, :udt_type
    field :fuzzy_name, :string

    field :sorter, list_of(:udts_sorter_input),
      default_value: [%{sort_type: :asc, sort_value: :name}]

    import_fields(:paginate_input)
  end

  input_object :udts_sorter_input do
    field :sort_type, :sort_type
    field :sort_value, :udts_sorter
  end
end
