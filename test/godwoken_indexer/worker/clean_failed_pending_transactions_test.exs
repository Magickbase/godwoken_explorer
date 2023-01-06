defmodule GodwokenIndexer.Worker.CleanFailedPendingTransactionsTest do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.{Polyjuice, Repo, Transaction}

  setup do
    start_time =
      Timex.now()
      |> Timex.shift(days: -4)
      |> Timex.beginning_of_day()

    insert(:pending_transaction, inserted_at: start_time) |> with_polyjuice()

    :ok
  end

  test "clean failed pending transaction", %{} do
    assert Repo.aggregate(Transaction, :count) == 1
    assert Repo.aggregate(Polyjuice, :count) == 1

    GodwokenIndexer.Worker.CleanFailedPendingTransactions.perform(%Oban.Job{})

    assert Repo.aggregate(Transaction, :count) == 0
    assert Repo.aggregate(Polyjuice, :count) == 0
  end
end
