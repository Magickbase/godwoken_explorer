defmodule GodwokenExplorer.Graphql.Resolvers.Account do
  alias GodwokenExplorer.Account

  # TODO: find account
  def account(_parent, _args, _resolution) do
    {:ok, %Account{}}
  end
end
