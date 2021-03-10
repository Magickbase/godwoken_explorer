# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
