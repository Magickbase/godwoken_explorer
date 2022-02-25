defmodule GodwokenExplorer.ETS.SmartContracts do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    :ets.new(GodwokenExplorer.ETS.SmartContracts, [:set, :public, :named_table, {:read_concurrency, true}])
    {:ok, nil}
  end

  def put(k, v) do
    :ets.insert(GodwokenExplorer.ETS.SmartContracts, {k, v})
  end

  def get(k) do
    case :ets.lookup(GodwokenExplorer.ETS.SmartContracts, k) do
      [{_, v}] -> v
      _ -> nil
    end
  end
end
