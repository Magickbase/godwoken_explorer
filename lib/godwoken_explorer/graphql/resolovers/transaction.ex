defmodule GodwokenExplorer.Graphql.Resolvers.Transaction do
  alias GodwokenExplorer.{Transaction}

  # TODO: add latest 10 blocks
  def latest_10_transactions(_parent, _args, _resolution) do
    {:ok, Transaction.latest_10_records()}
  end

  # TODO: show transaction
  def transaction(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show transactions
  def transactions(_parent, _args, _resolution) do
    {:ok, nil}
  end
end
