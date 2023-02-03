defmodule GodwokenExplorer.ETS.SmartContracts do
  @moduledoc """
  Caches smart contract's account ids
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    :ets.new(GodwokenExplorer.ETS.SmartContracts, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true}
    ])

    {:ok, nil}
  end

  def put(k, v) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    :ets.insert(GodwokenExplorer.ETS.SmartContracts, {k, v, now})
  end

  def get(k) do
    case :ets.lookup(GodwokenExplorer.ETS.SmartContracts, k) do
      [{_, v, now}] ->
        if check_expired(now) do
          v
        else
          nil
        end

      _ ->
        nil
    end
  end

  # one hour
  defp check_expired(t) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    abs(now - t) > 60 * 60
  end
end
