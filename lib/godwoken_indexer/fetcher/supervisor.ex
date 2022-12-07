defmodule GodwokenIndexer.Fetcher.Supervisor do
  use Supervisor

  def start_link(_) do
    {:ok, _} = Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      if Application.get_env(:godwoken_explorer, :on_off)[:udt_fetcher],
        do: [GodwokenIndexer.Fetcher.UDTBalance],
        else: []

    Supervisor.init(children, strategy: :one_for_one)
  end
end
