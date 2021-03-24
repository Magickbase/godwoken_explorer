use Mix.Config

config :godwoken_explorer,
  polyjuice_validator_code_hash: "0x6a946971979c019fe5096108267779775a141c9647936053b58358caa87bf5a2",
  layer2_lock_code_hash: "0x0000000000000000000000000000000000000000000000000000000000000001",
  udt_code_hash: "0x2f2336a04c3cec17e33b5956e1fa2024234f58480bba28ded7e0a8a73e2e956d",
  meta_contract_code_hash: "0xf6c494a0236ba9854c745e190ade9399a670c8efb4a876f978239ffcd445d0f3",
  state_validator_lock: %{
    code_hash: "0x624e029197ba4c7731cd0f57f8fa50855194838c8a77234e66850c98aeb36f55",
    hash_type: "type",
    args: "0x"
  },
  deposition_lock: %{
    code_hash: "0x8c5d41b03077151a75c691343067062bd76588aef507c495b77f8c5ec31d4cf5",
    hash_type: "type",
    args: "0x1fd2f78b7f7f07a43fbabd12da7e23f2c24a77ee5b0e446ff9d5bf3ba1dd7993"
  }

config :godwoken_explorer,
  init_godwoken_l1_block_number: 1798

config :godwoken_explorer, :basic_auth, username: "hello", password: "secret"

config :godwoken_explorer, GodwokenExplorer.Repo,
  username: "user",
  password: "password",
  database: "godwoken_explorer_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

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
    url: "http://localhost:8114/indexer",
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
