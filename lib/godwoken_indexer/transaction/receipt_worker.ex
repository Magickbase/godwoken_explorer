defmodule GodwokenIndexer.Transaction.ReceiptWorker do
  use GenServer

  alias GodwokenRPC
  alias GodwokenExplorer.{Repo, Polyjuice}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: ReceiptWorker)
  end

  def init(state) do
    {:ok, state}
  end

  def fetch_and_update(tx_hash) do
    GenServer.cast(ReceiptWorker, {:receipt, tx_hash})
  end

  def handle_cast({:receipt, tx_hash}, state) do
    case GodwokenRPC.fetch_receipt(tx_hash) do
      {:ok, gas_used} ->
        {:ok, _polyjuice} =
          Polyjuice
          |> Repo.get_by(tx_hash: tx_hash)
          |> Polyjuice.changeset(%{gas_used: gas_used})
          |> Repo.update()

      {:error, _} ->
        {:error, :unknown}
    end

    {:noreply, state}
  end
end
