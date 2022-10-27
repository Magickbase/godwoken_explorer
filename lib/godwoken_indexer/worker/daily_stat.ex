defmodule GodwokenIndexer.Worker.DailyStat do
  @moduledoc """
  Calculate daily chain data.
  """
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [where: 3, select: 3, order_by: 3]

  alias GodwokenExplorer.{Repo, DailyStat, Block, TokenTransfer}
  alias Decimal, as: D

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"datetime" => datetime_str}}) do
    datetime =
      if is_nil(datetime_str) do
        DateTime.utc_now()
      else
        datetime_str |> DateTime.from_iso8601() |> elem(1)
      end

    start_time =
      datetime
      |> Timex.shift(days: -1)
      |> Timex.beginning_of_day()

    end_time = datetime |> Timex.beginning_of_day()
    date = start_time |> Timex.to_date()

    with blocks when blocks != [] <-
           Block
           |> select([b], %{
             timestamp: b.timestamp,
             transaction_count: b.transaction_count,
             size: b.size,
             gas_used: b.gas_used,
             gas_limit: b.gas_limit,
             number: b.number
           })
           |> where([b], b.timestamp >= ^start_time and b.timestamp < ^end_time)
           |> order_by([b], asc: b.number)
           |> Repo.all() do
      total_block_count = blocks |> Enum.count()
      total_txn = blocks |> Enum.reduce(0, fn block, acc -> block[:transaction_count] + acc end)

      block_time_range_sec =
        Timex.diff(
          blocks |> List.last() |> Map.get(:timestamp),
          blocks |> List.first() |> Map.get(:timestamp),
          :seconds
        )

      avg_block_time = (block_time_range_sec / total_block_count) |> Float.round(2)

      avg_block_size =
        blocks
        |> Enum.reduce(0, fn block, acc -> block[:size] + acc end)
        |> Integer.floor_div(total_block_count)

      avg_gas_used =
        blocks
        |> Enum.reduce(D.new(0), fn block, acc -> block[:gas_used] |> D.add(acc) end)
        |> D.div(total_block_count)
        |> D.round(2)
        |> D.to_string()

      avg_gas_limit =
        blocks
        |> Enum.reduce(D.new(0), fn block, acc -> block[:gas_limit] |> D.add(acc) end)
        |> D.div(total_block_count)
        |> D.round(2)
        |> D.to_string()

      block_numbers = blocks |> Enum.map(fn %{number: number} -> number end)

      erc20_transfer_count =
        TokenTransfer |> where([tt], tt.block_number in ^block_numbers) |> Repo.aggregate(:count)

      DailyStat.insert_or_update(%{
        date: date,
        erc20_transfer_count: erc20_transfer_count,
        total_block_count: total_block_count,
        total_txn: total_txn,
        avg_block_size: avg_block_size,
        avg_block_time: avg_block_time,
        avg_gas_limit: avg_gas_limit,
        avg_gas_used: avg_gas_used
      })
    else
      _ ->
        DailyStat.insert_or_update(%{
          date: date,
          erc20_transfer_count: 0,
          total_block_count: 0,
          total_txn: 0,
          avg_block_size: 0,
          avg_block_time: 0,
          avg_gas_limit: 0,
          avg_gas_used: 0
        })
    end

    :ok
  end
end
