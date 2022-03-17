defmodule GodwokenExplorerWeb.API.DailyStatController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{DailyStat}

  def index(conn, %{start_date: start_date, end_date: end_date}) do
    results = DailyStat.by_date_range(start_date, end_date)

    json(conn, results)
  end
end
