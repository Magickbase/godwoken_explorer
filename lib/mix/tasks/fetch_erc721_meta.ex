defmodule Mix.Tasks.FetchErc721Meta do
  @moduledoc "Printed when the user requests `mix help fetch_erc721_meta`"
  @shortdoc " `mix fetch_erc721_meta`"

  alias GodwokenIndexer.Worker.ERC721UpdaterScheduler
  alias GodwokenExplorer.Repo

  use Mix.Task

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

    unfetched_udts =
      ERC721UpdaterScheduler.get_unfetched_udts(shift_seconds)
      |> ERC721UpdaterScheduler.process_limit(limit_value)
      |> Repo.all()

    length(unfetched_udts) |> IO.inspect(label: "unfetched_udts length")

    Enum.chunk_every(unfetched_udts, 50)
    |> Enum.reduce(0, fn e_unfetched_udts, acc ->
      IO.inspect("start to fetch #{acc}")
      ERC721UpdaterScheduler.fetch_and_update(e_unfetched_udts)
      acc + length(e_unfetched_udts)
    end)

    IO.inspect("done")
  end
end
