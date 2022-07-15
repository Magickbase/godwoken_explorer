defmodule GodwokenIndexer.Worker.CheckFastWithdrawal do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, WithdrawalHistory}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    from(wh in WithdrawalHistory,
      where: wh.is_fast_withdrawal == true and wh.state == :pending,
      limit: 50
    )
    |> Repo.all()
    |> Enum.each(fn withdrawal ->
      {:ok, %{"tx_status" => %{"status" => status}}} =
        GodwokenRPC.fetch_l1_tx(withdrawal.layer1_tx_hash)

      if status == "committed",
        do: WithdrawalHistory.changeset(withdrawal, %{state: :succeed}) |> Repo.update()
    end)

    :ok
  end
end
