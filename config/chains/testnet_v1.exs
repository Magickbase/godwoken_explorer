import Config

config :godwoken_explorer,
  rollup_type_hash: "0x4940246f168f4106429dc641add3381a44b5eef61e7754142f594e986671a575",
  meta_contract_validator_type_hash:
    "0xe37425948da964046bc470a77f5b3df3a661e8b0e0f8c1987239d9e4b9a629f5",
  l2_udt_code_hash: "0xe3e86ae888b3df3328842d11708b8ac30a7385c9f60d67f64efec65b7129e78e",
  polyjuice_validator_code_hash:
    "0x8755bcc380e3494b6a2ca9657d16fd2254f7570731c4b87867ed8b747b1b3457",
  eth_eoa_type_hash: "0x10571f91073fdc3cdef4ddad96b4204dd30d6355f3dda9a6d7fc0fa0326408da",
  tron_eoa_type_hash: "0x7e19e979f77305cdd61e39258b747809297ece6ab4d579ee38de8bce85d52124",
  eth_addr_reg_validator_script_type_hash:
    "0xea308236e06a55ea8951de922eb9eb7344ec8ac7e1909a29d3b580b97a980a4f",
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
  eth_addr_reg_id: "0x4",
  polyjuice_creator_id: 6

config :godwoken_explorer, :sourcify, chain_id: "71401"
