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
    raise "GODWOKEN_CHAIN environment variable is not set"
  else
    System.get_env("GODWOKEN_CHAIN")
    |> String.trim()
    |> String.downcase()
  end

import_config "prod/#{chain}.exs"
