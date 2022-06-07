defmodule GodwokenExplorer.SmartContract.Solidity.PublisherWorker do
  @moduledoc """
  Background smart contract verification worker.
  """

  use Oban.Worker, queue: :default

  alias GodwokenExplorer.SmartContract.Solidity.Publisher

  @impl Oban.Worker
  def perform(%Oban.Job{args: params}) do
    case Publisher.publish(params["address_hash"], params) do
      {:ok, _contract} ->
        :ok

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
