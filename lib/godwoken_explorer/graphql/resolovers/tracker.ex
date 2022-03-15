defmodule GodwokenExplorer.Graphql.Resolvers.Tracker do
  # TODO: get estimated_confirmation_time
  def estimated_confirmation_time(_parent, _args, _resolution) do
    {:ok, nil}
  end
end
