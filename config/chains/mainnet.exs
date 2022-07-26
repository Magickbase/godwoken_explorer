import Config

config :godwoken_explorer,
  meta_contract_code_hash: "0xcb99a9de6811812e79ffcda132f4d716dc26016cf89d94c832c51f9defa6b14f",
  udt_code_hash: "0xdb9896ecb952ab72f4f533d33fd9562fc1333fb6903899e93921efa9f8791408",
  polyjuice_validator_code_hash:
    "0x636b89329db092883883ab5256e435ccabeee07b52091a78be22179636affce8",
  layer2_lock_code_hash: "0x1563080d175bf8ddd44a48e850cecf0c0b4575835756eb5ffd53ad830931b9f9",
  eoa_code_hash: "0x0bc55f318d738bd1f50e5d950110f0ce5ea2230ec1b62defe1271e06e680476f",
  rollup_script_hash: "0x40d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b",
  rollup_cell_type: %{
    code_hash: "0xa9267ff5a16f38aa9382608eb9022883a78e6a40855107bb59f8406cce00e981",
    hash_type: "type",
    args: "0x2d8d67c8d73453c1a6d6d600e491b303910802e0cc90a709da9b15d26c5c48b3"
  },
  deposition_lock: %{
    code_hash: "0xe24164e2204f998b088920405dece3dcfd5c1fbcb23aecfce4b3d3edf1488897",
    hash_type: "type",
    args: "0x40d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b"
  },
  withdrawal_lock: %{
    code_hash: "0xf1717ee388b181fcb14352055c00b7ea7cd7c27350ffd1a2dd231e059dde2fed",
    hash_type: "type",
    args: "0x40d73f0d3c561fcaae330eabc030d8d96a9d0af36d0c5114883658a350cb9e3b"
  },
  init_godwoken_l1_block_number: 5_744_446,
  ckb_token_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000"

config :godwoken_explorer, :sourcify, chain_id: "71402"
