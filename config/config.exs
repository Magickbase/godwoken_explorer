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

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :godwoken_explorer,
  json_rpc_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: System.get_env("GODWOKEN_RPC_HTTP_URL") || "http://localhost:8119",
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10),
      hackney: [pool: :ethereum_jsonrpc]
    ]
  ]
config :godwoken_explorer,
  polyjuice_validator_code_hash: "0x6a946971979c019fe5096108267779775a141c9647936053b58358caa87bf5a2",
  layer2_lock_code_hash: "0x0000000000000000000000000000000000000000000000000000000000000001",
  udt_code_hash: "0x2f2336a04c3cec17e33b5956e1fa2024234f58480bba28ded7e0a8a73e2e956d",
  meta_contract_code_hash: "0xf6c494a0236ba9854c745e190ade9399a670c8efb4a876f978239ffcd445d0f3"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
