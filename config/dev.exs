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

config :godwoken_explorer, GodwokenExplorer.PromEx,
  disabled: true,
  grafana: :disabled,
  metrics_server: :disabled
