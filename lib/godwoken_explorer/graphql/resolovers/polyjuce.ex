defmodule GodwokenExplorer.Graphql.Resolvers.Polyjuice do
  alias GodwokenExplorer.Polyjuice
  alias GodwokenExplorer.Transaction

  alias GodwokenExplorer.Repo
  # import Ecto.Query

  def eth_hash(%Polyjuice{tx_hash: tx_hash}, _args, _resolution) do
    t = Repo.get(Transaction, tx_hash)
    {:ok, t.eth_hash}
  end

  def eth_hash(%{eth_hash: eth_hash}, _args, _resolution) do
    {:ok, eth_hash}
  end
end
