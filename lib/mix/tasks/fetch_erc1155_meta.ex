defmodule Mix.Tasks.FetchErc1155Meta do
  @moduledoc "Printed when the user requests `mix help fetch_erc1155_meta`"
  @shortdoc " `mix fetch_erc1155_meta 1 100`"

  alias GodwokenIndexer.Worker.ERC1155UpdaterScheduler

  use Mix.Task

  # require Logger

  # @chunk_size 100

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {shift_seconds, limit_value} =
      case args do
        [] ->
          {1, nil}

        [shift_seconds] ->
          {shift_seconds |> String.to_integer(), nil}

        [shift_seconds, limit] ->
          {shift_seconds |> String.to_integer(), limit |> String.to_integer()}
      end

    unfetched_udts = ERC1155UpdaterScheduler.get_unfetched_udts(shift_seconds, limit_value)

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
