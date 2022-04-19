import Config

config :godwoken_explorer, GodwokenExplorerWeb.Endpoint,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :godwoken_explorer, GodwokenExplorerWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/godwoken_explorer_web/(live|views)/.*(ex)$",
      ~r"lib/godwoken_explorer_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, backends: [:console], console: [format: "$time $metadata[$level] $message\n"]
config :logger, level: :debug

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

pg_username = System.get_env("PG_USERNAME", "postgres")
pg_password = System.get_env("PG_PADDWORD", "postgres")

pg_database = System.get_env("PG_DATABASE", "godwoken_explorer_dev")
pg_hostname = System.get_env("PG_HOSTNAME", "localhost")
pg_port = System.get_env("PG_PORT", "5432")

pg_url =
  System.get_env(
    "PG_DATABASE_URL",
    "postgresql://#{pg_username}:@#{pg_hostname}:#{pg_port}/#{pg_database}"
  )

pg_show_sensitive_data_on_connection_error =
  System.get_env("PG_SHOW_SENSITIVE_DATA_ON_CONNECTION_ERROR", "false") |> String.to_atom()

pg_pool_size = System.get_env("PG_POOL_SIZE", "10") |> String.to_integer()
pg_queue_target = System.get_env("PG_QUEUE_TARGET", "5000") |> String.to_integer()
pg_timeout = System.get_env("PG_TIMEOUT", "60000") |> String.to_integer()

chain =
  if is_nil(System.get_env("GODWOKEN_CHAIN")) do
    "aggron"
  else
    System.get_env("GODWOKEN_CHAIN")
    |> String.trim()
    |> String.downcase()
  end

config :godwoken_explorer, GodwokenExplorer.Repo,
  username: pg_username,
  password: pg_password,
  database: pg_database,
  hostname: pg_hostname,
  port: pg_port,
  show_sensitive_data_on_connection_error: pg_show_sensitive_data_on_connection_error,
  pool_size: pg_pool_size,
  queue_target: pg_queue_target,
  timeout: pg_timeout

import_config "dev/#{chain}.exs"
