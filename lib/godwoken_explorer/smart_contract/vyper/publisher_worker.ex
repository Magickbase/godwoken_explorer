defmodule GodwokenExplorer.SmartContract.Vyper.PublisherWorker do
  @moduledoc """
  Background smart contract verification worker.
  """

  # use Que.Worker, concurrency: 5

  alias GodwokenExplorer.Chain.Events.Publisher, as: EventsPublisher
  alias GodwokenExplorer.SmartContract.Vyper.Publisher

  def perform({address_hash, params, conn}) do
    result =
      case Publisher.publish(address_hash, params) do
        {:ok, _contract} = result ->
          result

        {:error, changeset} ->
          {:error, changeset}
      end

    EventsPublisher.broadcast(
      [{:contract_verification_result, {address_hash, result, conn}}],
      :on_demand
    )
  end
end
