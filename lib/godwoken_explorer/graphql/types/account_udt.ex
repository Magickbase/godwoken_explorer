defmodule GodwokenExplorer.Graphql.Types.AccountUDT do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.EIP55, as: MEIP55
  alias GodwokenExplorer.Graphql.Middleware.Downcase, as: MDowncase
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :account_udt_querys do
    @desc """
    TODO
    """
    field :account_current_udts, list_of(:account_current_udt) do
      arg(:input, non_null(:account_current_udts_input))
      middleware(MEIP55, [:address_hashes, :token_contract_address_hash])
      middleware(MDowncase, [:address_hashes, :token_contract_address_hash])
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.AccountUDT.account_current_udts/3)
    end

    @desc """
    TODO
    """
    field :account_current_bridged_udts, list_of(:account_current_bridged_udt) do
      arg(:input, non_null(:account_current_udts_input))
      middleware(MEIP55, [:address_hashes, :token_contract_address_hash])
      middleware(MDowncase, [:address_hashes, :token_contract_address_hash])
      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.AccountUDT.account_current_bridged_udts/3)
    end

    # @desc """
    # TODO
    # """
    # field :account_ckbs, list_of(:account_ckb) do
    #   arg(:input, non_null(:account_ckbs_input))
    #   middleware(MEIP55, [:address_hashes])
    #   middleware(MDowncase, [:address_hashes])
    #   resolve(&Resolvers.AccountUDT.account_ckbs/3)
    # end

    # @desc """
    # TODO
    # """
    # field :account_udts_by_contract_address, list_of(:account_udt) do
    #   arg(:input, non_null(:account_udt_contract_address_input))
    #   middleware(MEIP55, [:token_contract_address_hash])
    #   middleware(MDowncase, [:token_contract_address_hash])
    #   middleware(MTermRange, MTermRange.page_and_size_default_config())
    #   resolve(&Resolvers.AccountUDT.account_udts_by_contract_address/3)
    # end
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
  end

  object :account_current_bridged_udt do
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
  end

  input_object :account_ckbs_input do
    field :address_hashes, list_of(:string), default_value: []
    field :script_hashes, list_of(:string), default_value: []
  end

  input_object :account_current_udts_input do
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

  input_object :account_current_bridged_udts_input do
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
    field :udt_script_hash, :string
  end

  input_object :account_udt_contract_address_input do
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
    field :token_contract_address_hash, non_null(:string)
  end
end
