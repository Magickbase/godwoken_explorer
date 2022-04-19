import Config

config :godwoken_explorer, GodwokenExplorerWeb.Endpoint,
  # This is critical for ensuring web-sockets properly authorize.
  url: [host: ""],
  root: ".",
  server: true

config :logger,
  backends: [
    :console,
    {LoggerFileBackend, :info},
    {LoggerFileBackend, :error},
    Sentry.LoggerBackend
  ]

# Do not print debug messages in production
config :logger,
  info: [
    path: "log/info.log",
    level: :info,
    format: "$date $time $metadata[$level] $message\n",
    rotate: %{max_bytes: 52_428_800, keep: 19}
  ],
  error: [
    path: "log/error.log",
    level: :error,
    format: "$date $time $metadata[$level] $message\n",
    rotate: %{max_bytes: 52_428_800, keep: 19}
  ]

chain =
  if is_nil(System.get_env("GODWOKEN_CHAIN")) do
    "aggron"
  else
    System.get_env("GODWOKEN_CHAIN")
    |> String.trim()
    |> String.downcase()
  end

pg_username = System.get_env("PG_USERNAME", "postgres")
pg_password = System.get_env("PG_PADDWORD", "postgres")

pg_database = System.get_env("PG_DATABASE", "godwoken_explorer_dev")
pg_hostname = System.get_env("PG_HOSTNAME", "localhost")
pg_port = System.get_env("PG_PORT", "5432")

pg_show_sensitive_data_on_connection_error =
  System.get_env("PG_SHOW_SENSITIVE_DATA_ON_CONNECTION_ERROR", "false") |> String.to_atom()

pg_pool_size = System.get_env("PG_POOL_SIZE", "10") |> String.to_integer()
pg_queue_target = System.get_env("PG_QUEUE_TARGET", "5000") |> String.to_integer()
pg_timeout = System.get_env("PG_TIMEOUT", "10000") |> String.to_integer()

database_url =
  System.get_env("DATABASE_URL") ||
    "ecto://#{pg_username}:#{pg_password}@#{pg_hostname}:#{pg_port}/#{pg_database}"

maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

config :godwoken_explorer, GodwokenExplorer.Repo,
  database: pg_database,
  url: database_url,
  pool_size: pg_pool_size,
  timeout: pg_timeout,
  socket_options: maybe_ipv6

import_config "prod/#{chain}.exs"
