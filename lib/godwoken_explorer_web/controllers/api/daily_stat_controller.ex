defmodule GodwokenExplorerWeb.API.DailyStatController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{DailyStat, DailyStatView}

  plug JSONAPI.QueryParser, view: DailyStatView

  def index(conn, %{"start_date" => start_date, "end_date" => end_date}) do
    results = DailyStat.by_date_range(start_date, end_date)
    data =
      JSONAPI.Serializer.serialize(DailyStatView, results, conn)

    json(conn, data)
  end
end
