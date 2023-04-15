defmodule GodwokenExplorerWeb.API.DailyStatControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  alias Decimal, as: D

  setup do
    daily_stat = insert(:daily_stat)
    %{daily_stat: daily_stat}
  end

  describe "index" do
    test "return today's stat", %{conn: conn, daily_stat: daily_stat} do
      conn =
        get(
          conn,
          ~p"/api/daily_stats?start_date=#{Date.utc_today() |> Date.to_string()}&end_date=#{Date.utc_today() |> Date.to_string()}"
        )

      assert json_response(conn, 200) ==
               %{
                 "data" => [
                   %{
                     "attributes" => %{
                       "id" => daily_stat.id,
                       "date" => daily_stat.date |> Date.to_string(),
                       "total_txn" => daily_stat.total_txn,
                       "avg_block_time" => daily_stat.avg_block_time,
                       "avg_block_size" => daily_stat.avg_block_size,
                       "total_block_count" => daily_stat.total_block_count,
                       "erc20_transfer_count" => daily_stat.erc20_transfer_count,
                       "avg_gas_limit" => daily_stat.avg_gas_limit |> D.to_string(),
                       "avg_gas_used" => daily_stat.avg_gas_used |> D.to_string()
                     },
                     "id" => daily_stat.id |> Integer.to_string(),
                     "relationships" => %{},
                     "type" => "daily_stat"
                   }
                 ],
                 "included" => []
               }
    end
  end
end
