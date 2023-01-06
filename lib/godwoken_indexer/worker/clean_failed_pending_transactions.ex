defmodule GodwokenIndexer.Worker.CleanFailedPendingTransactions do
  @moduledoc """
  Remove failed pending transactions that send 3 days ago.
  """
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  require Logger

  alias GodwokenExplorer.{Polyjuice, Repo, Transaction}

  @failed_days 3

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    start_time =
      Timex.now()
      |> Timex.shift(days: -@failed_days)
      |> Timex.beginning_of_day()

    failed_pending_tx_hashes =
      from(t in Transaction,
        where: is_nil(t.block_hash) and t.inserted_at <= ^start_time,
        select: t.hash
      )
      |> Repo.all()

    if failed_pending_tx_hashes != [] do
      Logger.error("failed pending tx hashes: #{inspect(failed_pending_tx_hashes)}")

      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(
        :delete_all_polyjuice,
        from(p in Polyjuice, where: p.tx_hash in ^failed_pending_tx_hashes)
      )
      |> Ecto.Multi.delete_all(
        :delete_all_transaction,
        from(t in Transaction, where: t.hash in ^failed_pending_tx_hashes)
      )
      |> Repo.transaction()
    end

    :ok
  end
end
