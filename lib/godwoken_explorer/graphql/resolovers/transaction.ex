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

  # TODO: get polyjuice
  def polyjuice(%Transaction{hash: _hash}, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get block
  def block(%Transaction{}, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get account
  def account(%Transaction{}, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get udt
  def udt(%Transaction{}, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get smart_contract
  def smart_contract(%Transaction{}, _args, _resolution) do
    {:ok, nil}
  end
end
