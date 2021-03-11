defmodule GodwokenExplorer.Chain do
  import GodwokenRPC.Util, only: [stringify_and_unix_maps: 1]

  alias GodwokenExplorer.{Repo, Block}
  alias GodwokenExplorer.Counters.AccountsCounter
  alias GodwokenExplorer.Chain.Cache.{BlockCount, TransactionCount}

  def extract_db_name(db_url) do
    if db_url == nil do
      ""
    else
      db_url
      |> String.split("/")
      |> Enum.take(-1)
      |> Enum.at(0)
    end
  end

  def extract_db_host(db_url) do
    if db_url == nil do
      ""
    else
      db_url
      |> String.split("@")
      |> Enum.take(-1)
      |> Enum.at(0)
      |> String.split(":")
      |> Enum.at(0)
    end
  end

  def account_estimated_count do
    cached_value = AccountsCounter.fetch()

    if is_nil(cached_value) do
      %Postgrex.Result{rows: [[count]]} =
        Repo.query!("SELECT reltuples FROM pg_class WHERE relname = 'accounts';")

      count
    else
      cached_value
    end
  end

  @spec block_estimated_count() :: non_neg_integer()
  def block_estimated_count do
    cached_value = BlockCount.get_count()

    if is_nil(cached_value) do
      %Postgrex.Result{rows: [[count]]} =
        Repo.query!("SELECT reltuples FROM pg_class WHERE relname = 'blocks';")

      trunc(count)
    else
      cached_value
    end
  end

  @spec transaction_estimated_count() :: non_neg_integer()
  def transaction_estimated_count do
    cached_value = TransactionCount.get_count()

    if is_nil(cached_value) do
      %Postgrex.Result{rows: [[rows]]} =
        Repo.query!(
          "SELECT reltuples::BIGINT AS estimate FROM pg_class WHERE relname='transactions'"
        )

      trunc(rows)
    else
      cached_value
    end
  end

  def home_channel_data(blocks, txs) do
    %{
      block_list:
        blocks
        |> Enum.map(&(&1 |> Map.take([:hash, :number, :timestamp, :transaction_count])))
        |> Enum.map(fn record ->
          stringify_and_unix_maps(record)
        end),
      tx_list:
        txs
        |> Enum.map(fn tx ->
          tx
          |> Map.take([:hash, :from, :to, :type])
          |> Map.merge(%{timestamp: blocks |> List.first() |> Map.get(:timestamp), success: true})
        end)
        |> Enum.map(fn record ->
          stringify_and_unix_maps(record)
        end),
      statistic: %{
        account_count: account_estimated_count(),
        block_count: (blocks |> List.first() |> Map.get(:number)) + 1,
        tx_count: transaction_estimated_count(),
        tps: Block.transactions_count_per_second()
      }
    }
  end
end
