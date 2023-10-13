import Config

if File.exists?(".env.#{config_env()}") and config_env() in [:dev, :test] do
  Dotenv.load!(".env.#{config_env()}")
end

gwscan_endpoint_host = System.get_env("GWSCAN_ENDPOINT_HOST", "localhost")
gwscan_endpoint_port = System.get_env("GWSCAN_ENDPOINT_PORT", "4001") |> String.to_integer()
gwscan_endpoint_scheme = System.get_env("GWSCAN_ENDPOINT_SCHEME", "http")

default_gwscan_endpoint_secret_key = "RyKusGni7iTLOYLtHal3FRI4uKsV4mD/v25fyKBfVsxdrYChqL0IVTd07VvZoLx9"

gwscan_endpoint_secret_key = System.get_env("GODWOKEN_SCAN_ENDPOINT_SECRET_KEY", default_gwscan_endpoint_secret_key)

default_gwscan_endpoint_live_view_signing_salt = "Bd1hG/MH"

gwscan_endpoint_live_view_signing_salt =
  System.get_env(
    "GWSCAN_ENDPOINT_LIVE_VIEW_SIGNING_SALT",
    default_gwscan_endpoint_live_view_signing_salt
  )

gwscan_endpoint_check_origin =
  case System.get_env("GWSCAN_ENDPOINT_CHECK_ORIGIN", "false") do
    "false" ->
      false

    check_origin when is_bitstring(check_origin) ->
      check_origin
      |> String.trim()
      |> String.split(",")
      |> Enum.map(&String.trim(&1))

    _ ->
      false
  end

config :godwoken_explorer, GodwokenExplorerWeb.Endpoint,
  url: [host: gwscan_endpoint_host, port: gwscan_endpoint_port, scheme: gwscan_endpoint_scheme],
  http: [ip: {0, 0, 0, 0}, port: gwscan_endpoint_port],
  check_origin: gwscan_endpoint_check_origin,
  secret_key_base: gwscan_endpoint_secret_key,
  live_view: [signing_salt: gwscan_endpoint_live_view_signing_salt]

logger_level =
  if is_nil(System.get_env("GWSCAN_LOGER_LEVEL")) do
    :info
  else
    System.get_env("GWSCAN_LOGER_LEVEL")
    |> String.trim()
    |> String.downcase()
    |> String.to_atom()
  end

config :logger, level: logger_level

pg_pool_size = System.get_env("PG_POOL_SIZE", "20") |> String.to_integer()
pg_timeout = System.get_env("PG_TIMEOUT", "20000") |> String.to_integer()
pg_connect_timeout = System.get_env("PG_CONNECT_TIMEOUT", "30000") |> String.to_integer()
pg_queue_target = System.get_env("PG_QUEUE_TARGET", "5000") |> String.to_integer()

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

config :godwoken_explorer, GodwokenExplorer.Repo,
  url: database_url,
  pool_size: pg_pool_size,
  queue_target: pg_queue_target,
  timeout: pg_timeout,
  connect_timeout: pg_connect_timeout,
  socket_options: maybe_ipv6

gwscan_block_sync_woker_on_off = System.get_env("GWSCAN_BLOCK_SYNC_WORKER_ON_OFF", "false") |> String.to_atom()

gwscan_block_global_state_worker_on_off =
  System.get_env("GWSCAN_BLOCK_GLOBAL_STATE_WORKER_ON_OFF", "false") |> String.to_atom()

gwscan_block_bind_l1_l2_woker_on_off =
  System.get_env("GWSCAN_BLOCK_BIND_L1_L2_WORKER_ON_OFF", "false") |> String.to_atom()

gwscan_block_sync_l1_block_woker_on_off =
  System.get_env("GWSCAN_BLOCK_SYNC_L1_BLOCK_WORKER_ON_OFF", "false") |> String.to_atom()

gwscan_block_pending_transaction_woker_on_off =
  System.get_env("GWSCAN_BLOCK_PENDING_TRANSACTION_WORKER_ON_OFF", "false") |> String.to_atom()

gwscan_udt_fetcher_on_off = System.get_env("GWSCAN_UDT_FETCHER_ON_OFF", "false") |> String.to_atom()

config :godwoken_explorer, :on_off,
  sync_worker: gwscan_block_sync_woker_on_off,
  global_state_worker: gwscan_block_global_state_worker_on_off,
  bind_l1_l2_worker: gwscan_block_bind_l1_l2_woker_on_off,
  sync_l1_block_worker: gwscan_block_sync_l1_block_woker_on_off,
  pending_transaction_worker: gwscan_block_pending_transaction_woker_on_off,
  udt_fetcher: gwscan_udt_fetcher_on_off

gwscan_dashboard_username = System.get_env("GWSCAN_DASHBOARD_USERNAME", "admin")
gwscan_dashboard_password = System.get_env("GWSCAN_DASHBOARD_PASSWORD", "password")

config :godwoken_explorer, :basic_auth,
  username: gwscan_dashboard_username,
  password: gwscan_dashboard_password

godwoken_json_rpc_url =
  if System.get_env("GODWOKEN_JSON_RPC_URL") do
    System.get_env("GODWOKEN_JSON_RPC_URL")
  else
    raise "GODWOKEN_JSON_RPC_URL is not set"
  end

godwoken_mempool_rpc_url =
  if System.get_env("GODWOKEN_MEMPOOL_RPC_URL") do
    System.get_env("GODWOKEN_MEMPOOL_RPC_URL")
  else
    raise "GODWOKEN_MEMPOOL_RPC_URL is not set"
  end

ckb_rpc_url =
  if System.get_env("CKB_RPC_URL") do
    System.get_env("CKB_RPC_URL")
  else
    raise "CKB_RPC_URL is not set"
  end

config :godwoken_explorer,
  json_rpc_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: godwoken_json_rpc_url,
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ],
  mempool_rpc_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: godwoken_mempool_rpc_url,
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ],
  ckb_rpc_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: ckb_rpc_url,
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ]

gwscan_interval_sync_worker = System.get_env("GWSCAN_INTERVAL_SYNC_WORKER", "10") |> String.to_integer()

gwscan_interval_global_state_worker = System.get_env("GWSCAN_INTERVAL_GLOBAL_STATE_WORKER", "30") |> String.to_integer()

gwscan_interval_bind_l1_woker = System.get_env("GWSCAN_INTERVAL_BIND_L1_WORKER", "10") |> String.to_integer()

gwscan_interval_sync_deposition_worker =
  System.get_env("GWSCAN_INTERVAL_SYNC_DEPOSITION_WORKER", "2") |> String.to_integer()

gwscan_interval_pending_transaction_worker =
  System.get_env("GWSCAN_INTERVAL_PENDING_TRANSACTION_WORKER", "30") |> String.to_integer()

config :godwoken_explorer,
  sync_worker_interval: gwscan_interval_sync_worker,
  global_state_worker_interval: gwscan_interval_global_state_worker,
  bind_l1_worker_interval: gwscan_interval_bind_l1_woker,
  sync_deposition_worker_interval: gwscan_interval_sync_deposition_worker,
  pending_transaction_worker_interval: gwscan_interval_pending_transaction_worker

gwscan_sentry_dsn = System.get_env("GWSCAN_SENTRY_DSN", "")

config :sentry,
  filter: GodwokenExplorerWeb.SentryFilter,
  dsn: gwscan_sentry_dsn,
  environment_name: Mix.env()

gwscan_multiple_block_once = System.get_env("GWSCAN_MULTIPLE_BLOCK_ONCE", "false") |> String.to_atom()

gwscan_block_batch_size = System.get_env("GWSCAN_BLOCK_BATCH_SIZE", "1") |> String.to_integer()

gwscan_multiple_l1_block_once = System.get_env("GWSCAN_MULTIPLE_L1_BLOCK_ONCE", "false") |> String.to_atom()

gwscan_l1_block_batch_size = System.get_env("GWSCAN_L1_BLOCK_BATCH_SIZE", "1") |> String.to_integer()

config :godwoken_explorer,
  multiple_block_once: gwscan_multiple_block_once,
  block_batch_size: gwscan_block_batch_size,
  multiple_l1_block_once: gwscan_multiple_l1_block_once,
  l1_block_batch_size: gwscan_l1_block_batch_size

config :godwoken_explorer, :sourcify,
  server_url: System.get_env("SOURCIFY_SERVER_URL") || "https://sourcify.dev/server",
  # default is godwoken testnet
  chain_id: System.get_env("SOURCIFY_CHAIN_ID") || "71401",
  repo_url: System.get_env("SOURCIFY_REPO_URL") || "https://repo.sourcify.dev/contracts"

config :godwoken_explorer, GodwokenExplorer.ExchangeRates,
  store: :ets,
  enabled: System.get_env("DISABLE_EXCHANGE_RATES") != "true",
  coinmarketcap_api_key: System.get_env("EXCHANGE_RATES_COINMARKETCAP_API_KEY"),
  fetch_btc_value: System.get_env("EXCHANGE_RATES_FETCH_BTC_VALUE") == "true"

exchange_rates_source =
  cond do
    System.get_env("EXCHANGE_RATES_SOURCE") == "coin_gecko" ->
      GodwokenExplorer.ExchangeRates.Source.CoinGecko

    System.get_env("EXCHANGE_RATES_SOURCE") == "coin_market_cap" ->
      GodwokenExplorer.ExchangeRates.Source.CoinMarketCap

    true ->
      GodwokenExplorer.ExchangeRates.Source.CoinMarketCap
  end

config :godwoken_explorer, GodwokenExplorer.ExchangeRates.Source, source: exchange_rates_source

config :godwoken_explorer, Indexer, enabled: System.get_env("DISABLE_INDEXER") != "true"
config :godwoken_explorer, Web, enabled: System.get_env("DISABLE_WEB") != "true"
config :godwoken_explorer, Oban.Crontab, enabled: System.get_env("DISABLE_OBAN_CRONTAB") != "true"

config :godwoken_explorer, :bit, indexer_url: System.get_env("BIT_INDEXER_URL") || "https://indexer-v1.did.id"
