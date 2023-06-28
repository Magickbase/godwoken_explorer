defmodule GodwokenExplorer.Chain.Cache.Transactions do
  @moduledoc """
  Caches the latest imported transactions
  """

  use GodwokenExplorer.Chain.OrderedCache,
    name: :transactions,
    max_size: 10,
    preload: :block,
    ttl_check_interval: Application.get_env(:godwoken_explorer, __MODULE__)[:ttl_check_interval]

  @type id :: {non_neg_integer(), non_neg_integer()}

  def element_to_id(%{block_number: block_number, timestamp: timestamp, hash: hash}) do
    {block_number, timestamp, hash}
  end
end
