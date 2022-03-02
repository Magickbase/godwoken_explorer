import Config


config :godwoken_explorer,
  meta_contract_code_hash: "0x4a8ef5f6b366cb84e362dc747c314e32d5e2f1a6f64d118eaec6df2c36512ac0",
  udt_code_hash: "0x4e55cb08c3c772414e364aa5ed26609cfd3ee6619a2bb78c3bafa6f2f41b16b3",
  polyjuice_validator_code_hash:
    "0x848753a2b16c63682c7de4e6cc7167890ff3f821d61328f45386d91ece54373e",
  eth_eoa_type_hash: "0x6ac8027edfd86557a0b02fb8b9dce9ffc2bb2ac0b2f0352f74912bb546dc374c",
  tron_eoa_type_hash: "0xa289d7e6f46ae922a57691b42ce7b8ff9387f5d18ccce0287e14916a03cae51c",
  rollup_script_hash: "0xbd3f6ca6bdc273f1699e67a7b72cae0e0a7250646f168d03adab3892b5e2cfef",
  rollup_cell_type: %{
    code_hash: "0x3949a52e86048d6184641e7e441c543097559829daa9f60b7ee137031123ef24",
    hash_type: "type",
    args: "0xd35def1737c65ef34969c6cc93d5b87841434024e15d58693ea054059b58fc8d"
  },
  deposition_lock: %{
    code_hash: "0x6f46d7c451d63e584e60e6a748662df044e4ada30291e0d35aa1d0ddb1237f40",
    hash_type: "type",
    args: "0xbd3f6ca6bdc273f1699e67a7b72cae0e0a7250646f168d03adab3892b5e2cfef"
  },
  withdrawal_lock: %{
    code_hash: "0xc897744bffee22bae91afdf581e396d5d1f34313d2aa1b3fa8121e561f2bae59",
    hash_type: "type",
    args: "0xbd3f6ca6bdc273f1699e67a7b72cae0e0a7250646f168d03adab3892b5e2cfef"
  },
  init_godwoken_l1_block_number: 4_499_838,
  ckb_token_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  eth_token_script_hash: "0xa9eb9df467715766b009ad57cf4c7a2977bc8377d51ace37a3653f3bbb540b7c"

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
