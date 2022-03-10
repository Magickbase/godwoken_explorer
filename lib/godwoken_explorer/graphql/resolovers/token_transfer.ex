defmodule GodwokenExplorer.Graphql.Resolvers.TokenTransfer do
  alias GodwokenExplorer.{TokenTransfer}

  # TODO: show token_transfer
  def token_transfer(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show token_transfers
  def token_transfers(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get polyjuice
  def polyjuice(%TokenTransfer{}, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get block
  def block(%TokenTransfer{}, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get account
  def account(%TokenTransfer{}, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get udt
  def udt(%TokenTransfer{}, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get transaction
  def transaction(%TokenTransfer{}, _args, _resolution) do
    {:ok, nil}
  end
end
