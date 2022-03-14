import Config


config :godwoken_explorer,
  rollup_type_hash: "0x4940246f168f4106429dc641add3381a44b5eef61e7754142f594e986671a575",
  meta_contract_validator_type_hash: "0xe37425948da964046bc470a77f5b3df3a661e8b0e0f8c1987239d9e4b9a629f5",
  l2_udt_code_hash: "0xe3e86ae888b3df3328842d11708b8ac30a7385c9f60d67f64efec65b7129e78e",
  polyjuice_validator_code_hash:
    "0x8755bcc380e3494b6a2ca9657d16fd2254f7570731c4b87867ed8b747b1b3457",
  eth_eoa_type_hash: "0x10571f91073fdc3cdef4ddad96b4204dd30d6355f3dda9a6d7fc0fa0326408da",
  tron_eoa_type_hash: "0x7e19e979f77305cdd61e39258b747809297ece6ab4d579ee38de8bce85d52124",
  rollup_cell_type: %{
    code_hash: "0x0d3bfeaa292a59fcb58ed026e8f14e2167bd27f1765aa4b2af7d842b6123c6a9",
    hash_type: "type",
    args: "0x8137c84a9089f92fee684ac840532ee1133b012a9d42b6b76b74fbdde6999230"
  },
  deposition_lock: %{
    code_hash: "0xcc2b4e14d7dfeb1e72f7708ac2d7f636ae222b003bac6bccfcf8f4dfebd9c714",
    hash_type: "type",
    args: "0x4940246f168f4106429dc641add3381a44b5eef61e7754142f594e986671a575"
  },
  withdrawal_lock: %{
    code_hash: "0x318e8882bec0339fa20584f4791152e71d5b71c5dbd8bf988fd511373e142222",
    hash_type: "type",
    args: "0x4940246f168f4106429dc641add3381a44b5eef61e7754142f594e986671a575"
  },
  init_godwoken_l1_block_number: 4_672_922,
  ckb_token_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  eth_token_script_hash: "0xa9eb9df467715766b009ad57cf4c7a2977bc8377d51ace37a3653f3bbb540b7c",
  polyjuice_creator_id: "0x6"

config :godwoken_explorer, :basic_auth, username: "hello", password: "secret"

config :godwoken_explorer, GodwokenExplorer.Repo,
  username: "postgres",
  password: "password",
  database: "godwoken_explorer_dev_v1",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 20,
  timeout: 60_000

config :godwoken_explorer,
  # only read node
  json_rpc_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: "https://godwoken-testnet-web3-v1-rpc.ckbapp.dev",
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ],
  # mempool node
  mempool_rpc_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: "https://godwoken-testnet-web3-v1-rpc.ckbapp.dev",
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ],
  ckb_indexer_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: "http://116.62.22.144:8116",
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ],
  ckb_rpc_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: "http://116.62.22.144:8114",
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ]

config :godwoken_explorer,
  sync_worker_interval: 1,
  global_state_worker_interval: 30,
  bind_l1_worker_interval: 10,
  sync_deposition_worker_interval: 5

config :sentry,
  dsn: "",
  environment_name: "",
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: ""
  },
  included_environments: [""]
