defmodule GodwokenExplorer.Chain.Cache.SmartContract do
  @moduledoc """
  Cache for estimated transaction count.
  """

  @default_cache_period :timer.hours(1)

  use GodwokenExplorer.Chain.MapCache,
    name: :smart_contract,
    key: :account_ids,
    global_ttl: cache_period(),
    ttl_check_interval: :timer.minutes(15)

  require Logger

  import Ecto.Query

  alias GodwokenExplorer.{Repo, SmartContract}

  defp handle_fallback(:account_ids) do
    # This will get the task PID if one exists and launch a new task if not
    # See next `handle_fallback` definition
    account_ids = from(s in SmartContract, select: s.account_id) |> Repo.all()
    {:update, account_ids}
  end

  defp handle_fallback(_) do
    {:return, nil}
  end

  defp cache_period() do
    @default_cache_period
  end
end
