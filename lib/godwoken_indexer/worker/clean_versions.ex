defmodule GodwokenIndexer.Worker.CleanVersions do
  @moduledoc """
  Remove failed pending transactions that send 3 days ago.
  """
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, Version}

  @clean_days 1

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    start_time = Timex.now() |> Timex.shift(days: -@clean_days) |> Timex.beginning_of_day()

    from(v in Version,
      where: v.recorded_at <= ^start_time
    )
    |> Repo.delete_all()

    :ok
  end
end
