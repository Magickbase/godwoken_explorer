defmodule Mix.Tasks.FetchErc1155Meta do
  @moduledoc "Printed when the user requests `mix help fetch_erc1155_meta`"
  @shortdoc " `mix fetch_erc1155_meta`"

  alias GodwokenIndexer.Worker.ERC1155UpdaterScheduler

  use Mix.Task

  # require Logger

  # @chunk_size 100

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    shift_seconds = 1

    unfetched_udts = ERC1155UpdaterScheduler.get_unfetched_udts(shift_seconds, nil)

    length(unfetched_udts) |> IO.inspect(label: "unfetched_udts length")

    Enum.chunk_every(unfetched_udts, 50)
    |> Enum.reduce(0, fn e_unfetched_udts, acc ->
      IO.inspect("start to fetch #{acc}")
      ERC1155UpdaterScheduler.fetch_and_update(e_unfetched_udts)
      acc + length(e_unfetched_udts)
    end)

    IO.inspect("done")
  end
end
