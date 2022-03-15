defmodule GodwokenExplorer.Graphql.Resolvers.Log do
  alias GodwokenExplorer.Log

  # TODO: show logs
  def logs(_parent, _args, _resolution) do
    {:ok, [%Log{}]}
  end
end
