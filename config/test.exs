import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :godwoken_explorer, GodwokenExplorer.Repo, pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :godwoken_explorer, GodwokenExplorerWeb.Endpoint,
  http: [port: 4002],
  server: false

config :godwoken_explorer, Oban, testing: :manual

# Print only warnings and errors during test
config :logger, level: :warning

# config :godwoken_explorer, GodwokenExplorer.PromEx,
#   disabled: true,
#   grafana: :disabled,
#   metrics_server: :disabled
