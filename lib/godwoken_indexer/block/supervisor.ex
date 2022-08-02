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
      Enum.reduce(children, [], fn child, acc ->
        children(child) ++ acc
      end)

    Supervisor.init(childs, strategy: :one_for_one, max_restarts: 6)
  end

  defp children(GodwokenIndexer.Block.SyncWorker) do
    if Application.get_env(:godwoken_explorer, :on_off)[:sync_worker] do
      [GodwokenIndexer.Block.SyncWorker]
    else
      []
    end
  end

  defp children(GodwokenIndexer.Block.GlobalStateWorker) do
    if Application.get_env(:godwoken_explorer, :on_off)[:global_state_worker] do
      [GodwokenIndexer.Block.GlobalStateWorker]
    else
      []
    end
  end

  defp children(GodwokenIndexer.Block.BindL1L2Worker) do
    if Application.get_env(:godwoken_explorer, :on_off)[:bind_l1_l2_worker] do
      [GodwokenIndexer.Block.BindL1L2Worker]
    else
      []
    end
  end

  defp children(GodwokenIndexer.Block.SyncL1BlockWorker) do
    if Application.get_env(:godwoken_explorer, :on_off)[:sync_l1_block_worker] do
      [GodwokenIndexer.Block.SyncL1BlockWorker]
    else
      []
    end
  end
end
