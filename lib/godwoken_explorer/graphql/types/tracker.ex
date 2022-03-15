defmodule GodwokenExplorer.Graphql.Types.Tracker do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :web3_tracker_querys do
    field :estimated_confirmation_time, :estimated_confirmation_time do
      resolve(&Resolvers.Tracker.estimated_confirmation_time/3)
    end
  end

  object :estimated_confirmation_time do
    field :seconds, :integer
  end
end
