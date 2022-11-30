defmodule GodwokenIndexer.Workers.Sourcify do
  alias GodwokenExplorer.Graphql.Sourcify

  use Oban.Worker, queue: :default, unique: [period: :infinity, states: Oban.Job.states()]
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"eth_address" => eth_address}}) do
    Sourcify.verify_and_update_from_sourcify(eth_address)
    :ok
  end
end
