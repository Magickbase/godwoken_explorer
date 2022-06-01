defmodule GodwokenIndexer.Server do
  use Supervisor

  def start_link(_) do
    {:ok, _} = Supervisor.start_link(__MODULE__, [], name: :indexer_server)
  end

  def init(_) do
    children = [
      GodwokenIndexer.Block.Supervisor,
      GodwokenIndexer.Fetcher.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
