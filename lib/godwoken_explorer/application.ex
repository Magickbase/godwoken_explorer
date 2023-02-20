defmodule GodwokenExplorer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    base_children = [
      GodwokenExplorer.Repo,
      GodwokenExplorer.Chain.Cache.Blocks,
      GodwokenExplorer.Chain.Cache.Transactions,
      {Oban, oban_config()}
    ]

    cache_children = [
      con_cache_child_spec(:cache_sc,
        ttl_check_interval: :timer.minutes(15),
        global_ttl: :timer.hours(1)
      )
    ]

    web_children =
      if should_start?(Web) do
        [
          GodwokenExplorerWeb.Telemetry,
          GodwokenExplorerWeb.Endpoint,
          {Phoenix.PubSub, name: GodwokenExplorer.PubSub},
          Supervisor.child_spec({Task.Supervisor, name: GodwokenExplorer.MarketTaskSupervisor},
            id: Explorer.MarketTaskSupervisor
          ),
          # graphql api
          GodwokenExplorer.Counters.AddressTransactionsCounter,
          GodwokenExplorer.Counters.AddressTokenTransfersCounter,
          GodwokenExplorer.Chain.Cache.TokenExchangeRate,
          GodwokenExplorer.Chain.Cache.AddressBitAlias,

          # web home api
          GodwokenExplorer.Counters.AccountsCounter,
          GodwokenExplorer.Counters.AverageBlockTime,
          GodwokenExplorer.Chain.Cache.TransactionCount,
          # api
          GodwokenExplorer.Chain.Cache.PolyVersion,
          # admin
          GodwokenExplorer.SmartContract.SolcDownloader,
          GodwokenExplorer.SmartContract.VyperDownloader
        ]
      else
        []
      end

    indexer_children = if should_start?(Indexer), do: [GodwokenIndexer.Server], else: []

    children = base_children ++ cache_children ++ web_children ++ indexer_children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GodwokenExplorer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp con_cache_child_spec(name, params) do
    params = Keyword.put(params, :name, name)

    Supervisor.child_spec(
      {
        ConCache,
        params
      },
      id: {ConCache, name}
    )
  end

  defp should_start?(process) do
    Application.get_env(:godwoken_explorer, process, [])[:enabled] == true
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GodwokenExplorerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    if should_start?(Oban.Crontab) do
      Application.fetch_env!(:godwoken_explorer, Oban)
    else
      [repo, _plugins, queues] = Application.fetch_env!(:godwoken_explorer, Oban)
      [repo, queues]
    end
  end
end
