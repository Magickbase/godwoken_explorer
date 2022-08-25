defmodule GodwokenExplorer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias GodwokenExplorerWeb.RealtimeEventHandler

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      GodwokenExplorer.Repo,
      # Start the Telemetry supervisor
      GodwokenExplorerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: GodwokenExplorer.PubSub},
      # Start the Endpoint (http/https)
      GodwokenExplorerWeb.Endpoint,
      {Registry, keys: :duplicate, name: Registry.ChainEvents, id: Registry.ChainEvents},
      {RealtimeEventHandler, name: RealtimeEventHandler},
      GodwokenExplorer.Chain.Events.Listener,
      GodwokenIndexer.Server,
      GodwokenExplorer.Counters.AccountsCounter,
      GodwokenExplorer.Counters.AverageBlockTime,
      GodwokenExplorer.Counters.AddressTransactionsCounter,
      GodwokenExplorer.Counters.AddressTokenTransfersCounter,
      GodwokenExplorer.Chain.Cache.BlockCount,
      GodwokenExplorer.Chain.Cache.TransactionCount,
      GodwokenExplorer.Chain.Cache.Blocks,
      GodwokenExplorer.Chain.Cache.Transactions,
      GodwokenExplorer.Chain.Cache.PolyVersion,
      GodwokenExplorer.ETS.SmartContracts,
      GodwokenExplorer.SmartContract.SolcDownloader,
      GodwokenExplorer.SmartContract.VyperDownloader,
      {Oban, oban_config()},
      GodwokenExplorer.PromEx
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GodwokenExplorer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GodwokenExplorerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.fetch_env!(:godwoken_explorer, Oban)
  end
end
