defmodule GodwokenExplorer.Graphql.Resolvers.AccountUDT do
  alias GodwokenExplorer.AccountUDT

  # TODO: show account udt
  def account_udt(_parent, _args, _resolution) do
    {:ok, %AccountUDT{}}
  end

  # TODO: find account
  def account_udts(_parent, _args, _resolution) do
    {:ok, nil}
  end

end
