defmodule GodwokenExplorer.Graphql.Resolvers.Polyjuice do
  alias GodwokenExplorer.Graphql.Dataloader.BatchPolyjuice
  alias GodwokenExplorer.Account
  alias GodwokenExplorer.Polyjuice
  alias GodwokenExplorer.PolyjuiceCreator
  alias GodwokenExplorer.Transaction
  alias GodwokenExplorer.TokenTransfer

  import GodwokenRPC.Util, only: [script_to_hash: 1]
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

  def created_account(%PolyjuiceCreator{} = creator, _args, _resolution) do
    account_script = %{
      "code_hash" => creator.code_hash,
      "hash_type" => creator.hash_type,
      "args" => creator.script_args
    }

    l2_script_hash = script_to_hash(account_script)

    batch(
      {BatchPolyjuice, :polyjuice_creator_account, Account},
      l2_script_hash,
      fn batch_results ->
        {:ok, Map.get(batch_results, l2_script_hash)}
      end
    )
  end
end
