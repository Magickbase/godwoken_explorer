defmodule GodwokenIndexer.Block.Supervisor do
  use Supervisor

  def start_link(_) do
    {:ok, _} = Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      GodwokenIndexer.Block.SyncWorker,
      GodwokenIndexer.Block.GlobalStateWorker,
      GodwokenIndexer.Block.BindL1L2Worker,
      GodwokenIndexer.Block.SyncL1BlockWorker
    ]

    childs =
      if Application.get_env(:godwoken_explorer, :close_local_sync) do
        []
      else
        children
      end

    Supervisor.init(childs, strategy: :one_for_one)
  end
end
