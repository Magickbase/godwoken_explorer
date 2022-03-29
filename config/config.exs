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

config :logger, backends:
  [{LoggerFileBackend, :debug}, {LoggerFileBackend, :info}, {LoggerFileBackend, :warn}, {LoggerFileBackend, :error}]

config :godwoken_explorer, GodwokenExplorer.Counters.AccountsCounter,
  enabled: true,
  enable_consolidation: true,
  update_interval_in_seconds:  30 * 6

config :godwoken_explorer, GodwokenExplorer.Chain.Cache.Blocks,
  ttl_check_interval: false

config :godwoken_explorer, GodwokenExplorer.Chain.Cache.Transactions,
  ttl_check_interval: false

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

# UTC
config :godwoken_explorer, GodwokenExplorer.Scheduler,
  storage: QuantumStoragePersistentEts,
  jobs: [
    {"01 00 * * *", {GodwokenExplorer.UDT, :refresh_supply, []}},
    {"10 00 * * *", {GodwokenExplorer.DailyStat, :refresh_yesterday_data, [DateTime.utc_now]}},
    {"*/2 * * * *", {GodwokenExplorer.Account, :check_account_and_create, []}}
  ]

  # need to override by runtime config
  config  :godwoken_explorer, :special_address,
    layer2_ckb_smart_contract_address_1: "0x0000000000000000000000000000000000000000",
    layer2_ckb_smart_contract_address_2: "0x0000000000000000000000000000000000000000"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
