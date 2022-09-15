# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :godwoken_explorer,
  ecto_repos: [GodwokenExplorer.Repo],
  realtime_events_sender: GodwokenExplorer.Chain.Events.SimpleSender

# Configures the endpoint
config :godwoken_explorer, GodwokenExplorerWeb.Endpoint,
  url: [host: "localhost"],
  check_origin: false,
  secret_key_base: "RyKusGni7iTLOYLtHal3FRI4uKsV4mD/v25fyKBfVsxdrYChqL0IVTd07VvZoLx9",
  render_errors: [view: GodwokenExplorerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GodwokenExplorer.PubSub,
  live_view: [signing_salt: "Bd1hG/MH"]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :logger,
  backends: [
    {LoggerFileBackend, :debug},
    {LoggerFileBackend, :info},
    {LoggerFileBackend, :warn},
    {LoggerFileBackend, :error}
  ]

config :godwoken_explorer, GodwokenExplorer.Counters.AccountsCounter,
  enabled: true,
  enable_consolidation: true,
  update_interval_in_seconds: 30 * 6

config :godwoken_explorer, GodwokenExplorer.Chain.Cache.Blocks, ttl_check_interval: false

config :godwoken_explorer, GodwokenExplorer.Chain.Cache.Transactions, ttl_check_interval: false

config :torch,
  otp_app: :godwoken_explorer,
  template_format: "eex"

config :ex_audit,
  ecto_repos: [GodwokenExplorer.Repo],
  version_schema: GodwokenExplorer.Version,
  tracked_schemas: [
    GodwokenExplorer.CheckInfo
  ]

config :jsonapi,
  remove_links: true

config :godwoken_explorer, Oban,
  repo: GodwokenExplorer.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       {"10 00 * * *", GodwokenIndexer.Worker.DailyStat, args: %{datetime: nil}},
       {"*/1 * * * *", GodwokenIndexer.Worker.CheckLostAccount},
       {"*/10 * * * *", GodwokenIndexer.Worker.CheckContractCode},
       {"*/30 * * * *", GodwokenIndexer.Worker.RefreshBridgedUDTSupply},
       {"* */1 * * *", GodwokenIndexer.Worker.UDTUpdater},
       {"*/1 * * * *", GodwokenExplorer.Graphql.Workers.SmartContractRegister},
       {"*/1 * * * *", GodwokenIndexer.Worker.ERC721UpdaterScheduler}
     ]}
  ],
  queues: [default: 3]

gwscan_graphiql =
  if is_nil(System.get_env("GWSCAN_GRAPHIQL")) do
    true
  else
    System.get_env("GWSCAN_GRAPHIQL") |> String.to_atom()
  end

config :godwoken_explorer, :graphiql, gwscan_graphiql

config :godwoken_explorer, GodwokenExplorerWeb.ApiRouter,
  writing_enabled: false,
  reading_enabled: true

config :godwoken_explorer,
  allowed_evm_versions:
    System.get_env("ALLOWED_EVM_VERSIONS") ||
      "homestead,tangerineWhistle,spuriousDragon,byzantium,constantinople,petersburg,istanbul,berlin,london,default",
  solc_bin_api_url: "https://solc-bin.ethereum.org"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

chain =
  if is_nil(System.get_env("GODWOKEN_CHAIN")) do
    "testnet_v1_1"
  else
    System.get_env("GODWOKEN_CHAIN")
    |> String.trim()
    |> String.downcase()
  end

import_config "chains/#{chain}.exs"
