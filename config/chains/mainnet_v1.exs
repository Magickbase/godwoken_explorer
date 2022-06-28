import Config

config :godwoken_explorer,
  meta_contract_validator_type_hash:
    "0x2c0b586137cb942f92cc3f84f62d77924b560e4088667f6f47012ecfa828e184",
  l2_udt_code_hash: "0x990027acd7058ec1b45df9d7448c0c5407fc17dde4b9b769f594d613c8053084",
  l1_udt_code_hash: "0x5e7a36a77e68eecc013dfa2fe6a23f3b6c344b04005808694ae6dd45eea4cfd5",
  rollup_type_hash: "0x1ca35cb5fda4bd542e71d94a6d5f4c0d255d6d6fba73c41cf45d2693e59b3072",
  polyjuice_validator_code_hash:
    "0x83d5d8841518e8db686909d27c821398491f475ed5f1cd392c36e83f4252c4ac",
  eth_addr_reg_validator_script_type_hash:
    "0xc55c5ede907d13ac1e744cff8ce4386b9dc5aad905d8f3badfd9419efe49eeb2",
  eth_eoa_type_hash: "0x096df264f38fff07f3acd318995abc2c71ae0e504036fe32bc38d5b6037364d4",
  rollup_cell_type: %{
    code_hash: "0xfef1d086d9f74d143c60bf03bd04bab29200dbf484c801c72774f2056d4c6718",
    hash_type: "type",
    args: "0xab21bfe2bf85927bb42faaf3006a355222e24d5ea1d4dec0e62f53a8e0c04690"
  },
  deposition_lock: %{
    code_hash: "0xff602581f07667eef54232cce850cbca2c418b3418611c132fca849d1edcd775",
    hash_type: "type",
    args: "0x1ca35cb5fda4bd542e71d94a6d5f4c0d255d6d6fba73c41cf45d2693e59b3072"
  },
  withdrawal_lock: %{
    code_hash: "0x3714af858b8b82b2bb8f13d51f3cffede2dd8d352a6938334bb79e6b845e3658",
    hash_type: "type",
    args: "0x1ca35cb5fda4bd542e71d94a6d5f4c0d255d6d6fba73c41cf45d2693e59b3072"
  },
  init_godwoken_l1_block_number: 7_469_392,
  ckb_token_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  eth_addr_reg_id: "0x2",
  polyjuice_creator_id: 4
