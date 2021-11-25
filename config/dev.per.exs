use Mix.Config

config :godwoken_explorer,
  meta_contract_code_hash: "0xd6d4b52ed2882cb0b2e1f802817c0ab05bd27da89a41ceddb25e0e347689ce69",
  udt_code_hash: "0xb6d6a2882d3d08cea565047bfe901cb2afe0cb790ea5e1b61e0532ef237c4a02",
  polyjuice_validator_code_hash:
    "0xbeb77e49c6506182ec0c02546aee9908aafc1561ec13beb488d14184c6cd1b79",
  layer2_lock_code_hash: "0xdeec13a7b8e100579541384ccaf4b5223733e4a5483c3aec95ddc4c1d5ea5b22",
  eoa_code_hash: "0x28380fadb43a6f139d61a2509b69ecd2fbb2f61847ef6d39371b4f906c151ab5",
  rollup_script_hash: "0x4cc2e6526204ae6a2e8fcf12f7ad472f41a1606d5b9624beebd215d780809f6a",
  rollup_cell_type: %{
    code_hash: "0x5c365147bb6c40e817a2a53e0dec3661f7390cc77f0c02db138303177b12e9fb",
    hash_type: "type",
    args: "0x213743d13048e9f36728c547ab736023a7426e15a3d7d1c82f43ec3b5f266df2"
  },
  deposition_lock: %{
    code_hash: "0x5a2506bb68d81a11dcadad4cb7eae62a17c43c619fe47ac8037bc8ce2dd90360",
    hash_type: "type",
    args: "0x4cc2e6526204ae6a2e8fcf12f7ad472f41a1606d5b9624beebd215d780809f6a"
  },
  init_godwoken_l1_block_number: 2_286_200,
  ckb_token_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  eth_token_script_hash: "0xa9eb9df467715766b009ad57cf4c7a2977bc8377d51ace37a3653f3bbb540b7c"

config :godwoken_explorer, :basic_auth, username: "hello", password: "secret"

config :godwoken_explorer, GodwokenExplorer.Repo,
  username: "user",
  password: "password",
  database: "godwoken_explorer_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  ownership_timeout: 60_000,
  timeout: 60_000

config :godwoken_explorer,
  json_rpc_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: "http://localhost:8119",
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ],
  ckb_indexer_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: "http://localhost:8116",
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ],
  ckb_rpc_named_arguments: [
    http: GodwokenRPC.HTTP.HTTPoison,
    url: "http://localhost:8114",
    http_options: [
      recv_timeout: :timer.minutes(10),
      timeout: :timer.minutes(10)
    ]
  ]

config :ethereumex,
  client_type: :http,
  url: "http://localhost:8119"

config :godwoken_explorer,
  sync_worker_interval: 1,
  global_state_worker_interval: 30,
  bind_l1_worker_interval: 5
