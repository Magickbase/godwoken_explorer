defmodule GodwokenExplorer.Graphql.Types.Statistic do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :web3_statistic_querys do
    field :erc20_statistic, :erc20_statistic do
      arg(:input, :smart_contract_input)
      resolve(&Resolvers.Statistic.erc20_statistic/3)
    end
  end

  object :statistic_querys do
    field :home_page_statistic, :home_page_statistic do
      resolve(&Resolvers.Statistic.home_page_statistic/3)
    end
  end

  object :statistic_mutations do
  end

  object :home_page_statistic do
    field :account_count, :integer
    field :block_count, :integer
    field :tx_count, :integer
    field :tps, :float
  end

  object :erc20_statistic do
    field :total_supply, :decimal
    field :erc_20_circulating_supply, :erc_20_circulating_supply
  end

  object :erc_20_circulating_supply do
    field :circulating_supply, :decimal
    field :updated_block_number, :integer
  end
end
