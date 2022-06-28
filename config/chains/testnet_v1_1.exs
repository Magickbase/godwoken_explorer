import Config

config :godwoken_explorer,
  meta_contract_validator_type_hash:
    "0x37b25df86ca495856af98dff506e49f2380d673b0874e13d29f7197712d735e8",
  l2_udt_code_hash: "0xb6176a6170ea33f8468d61f934c45c57d29cdc775bcd3ecaaec183f04b9f33d9",
  l1_udt_code_hash: "0xc5e5dcf215925f7ef4dfaf5f4b4f105bc321c02776d6e7d52a1db3fcd9d011a4",
  rollup_type_hash: "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8",
  polyjuice_validator_code_hash:
    "0x1629b04b49ded9e5747481f985b11cba6cdd4ffc167971a585e96729455ca736",
  eth_addr_reg_validator_script_type_hash:
    "0xa30dcbb83ebe571f49122d8d1ce4537679ebf511261c8ffaaa6679bf9fdea3a4",
  eth_eoa_type_hash: "0x07521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec0",
  rollup_cell_type: %{
    code_hash: "0x1e44736436b406f8e48a30dfbddcf044feb0c9eebfe63b0f81cb5bb727d84854",
    hash_type: "type",
    args: "0x86c7429247beba7ddd6e4361bcdfc0510b0b644131e2afb7e486375249a01802"
  },
  deposition_lock: %{
    code_hash: "0x50704b84ecb4c4b12b43c7acb260ddd69171c21b4c0ba15f3c469b7d143f6f18",
    hash_type: "type",
    args: "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8"
  },
  withdrawal_lock: %{
    code_hash: "0x06ae0706bb2d7997d66224741d3ec7c173dbb2854a6d2cf97088796b677269c6",
    hash_type: "type",
    args: "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd8"
  },
  init_godwoken_l1_block_number: 5_293_197,
  ckb_token_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  eth_addr_reg_id: "0x2",
  polyjuice_creator_id: 4
