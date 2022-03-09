defmodule GodwokenExplorer.Graphql.Resolvers.SmartContract do
  alias GodwokenExplorer.{SmartContract}

  # TODO: show smart_contracts
  def smart_contracts(_parent, _args, _resolution) do
    {:ok, %SmartContract{}}
  end
end
