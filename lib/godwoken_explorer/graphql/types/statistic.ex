defmodule GodwokenExplorer.Graphql.Types.Statistic do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

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
end
