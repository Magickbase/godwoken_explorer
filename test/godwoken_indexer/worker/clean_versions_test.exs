defmodule GodwokenIndexer.Worker.CleanFailedPendingTransactionsTest do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.{Version, Repo}

  setup do
    start_time =
      Timex.now()
      |> Timex.shift(days: -4)
      |> Timex.beginning_of_day()

    insert(:version, recorded_at: start_time)

    :ok
  end

  test "clean old versions", %{} do
    assert Repo.aggregate(Version, :count) == 1

    GodwokenIndexer.Worker.CleanVersions.perform(%Oban.Job{})

    assert Repo.aggregate(Version, :count) == 0
  end
end
