defmodule GodwokenExplorer.Graphql.Resolvers.SmartContract do
  alias GodwokenExplorer.{SmartContract}

  # TODO: show udt
  def udt(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show smart_contract
  def smart_contract(_parent, _args, _resolution) do
    {:ok, %SmartContract{}}
  end

    # TODO: show smart_contracts
  def smart_contracts(_parent, _args, _resolution) do
    {:ok, nil}
  end
end
