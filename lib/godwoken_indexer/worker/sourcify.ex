defmodule GodwokenIndexer.Worker.Sourcify do
  use Oban.Worker, queue: :default, unique: [period: :infinity, states: Oban.Job.states()]

  alias GodwokenExplorer.Graphql.Sourcify
  alias GodwokenExplorer.Account

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"eth_address" => eth_address}}) do
    Account.handle_eoa_to_contract(eth_address)

    Sourcify.verify_and_update_from_sourcify(eth_address)
    :ok
  end
end
