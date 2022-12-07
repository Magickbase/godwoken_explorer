defmodule GodwokenExplorer.Graphql.Resolvers.Polyjuice do
  alias GodwokenExplorer.Graphql.Dataloader.BatchPolyjuice
  alias GodwokenExplorer.Polyjuice
  alias GodwokenExplorer.Transaction
  alias GodwokenExplorer.TokenTransfer

  import Absinthe.Resolution.Helpers, only: [batch: 3]

  def eth_hash(%Polyjuice{tx_hash: tx_hash}, _args, _resolution) do
    batch({BatchPolyjuice, :eth_hash, Transaction}, tx_hash, fn batch_results ->
      {:ok, Map.get(batch_results, tx_hash)}
    end)
  end

  def eth_hash(%TokenTransfer{transaction_hash: eth_hash}, _args, _resolution) do
    {:ok, eth_hash}
  end

  def eth_hash(%{eth_hash: eth_hash}, _args, _resolution) do
    {:ok, eth_hash}
  end
end
