defmodule GodwokenIndexer.Block.Supervisor do
  use Supervisor

   def start_link(_) do
     {:ok, _} = Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [GodwokenIndexer.Block.Worker]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
