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
    path: "/etc/logs_data/gwscan/info.log",
    level: :info,
    format: "$date $time $metadata[$level] $message\n",
    rotate: %{max_bytes: 52_428_800, keep: 19}
  ],
  error: [
    path: "/etc/logs_data/gwscan/error.log",
    level: :error,
    format: "$date $time $metadata[$level] $message\n",
    rotate: %{max_bytes: 52_428_800, keep: 19}
  ]

config :godwoken_explorer, GodwokenExplorer.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: [
    host: System.get_env("GRAFANA_HOST"),
    auth_token: System.get_env("GRAFANA_AUTH_TOKEN"),
    folder_name: System.get_env("GRAFANA_FOLDER_NAME"),
    upload_dashboards_on_start: true,
    annotate_app_lifecycle: true
  ],
  metrics_server: [
    port: "9568",
    path: "/metrics"
  ]
