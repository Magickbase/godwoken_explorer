defmodule GodwokenIndexer.Block.Supervisor do
  use Supervisor

   def start_link(_) do
     {:ok, _} = Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      GodwokenIndexer.Block.SyncWorker,
      GodwokenIndexer.Block.GlobalStateWorker,
      # GodwokenIndexer.Block.BindL1L2Worker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
