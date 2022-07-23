mod generated;
pub use generated::packed;
use packed::MetaContractArgs;
use packed::MetaContractArgsUnion;
use packed::GlobalState;
use packed::GlobalStateV0;
use packed::DepositLockArgs;
use packed::WithdrawalLockArgs;
use packed::ETHAddrRegArgs;
use packed::ETHAddrRegArgsUnion;
use molecule::prelude::Entity;
use ckb_hash::blake2b_256;

mod atoms {
    rustler::atoms! {
        ok,
    }
}

#[rustler::nif]
fn parse_meta_contract_args(arg: String) -> ((String, String, String), (u32, String))  {
    let decoded_meat_contract = hex::decode(arg).unwrap();
    let meta_contract_args = MetaContractArgs::from_slice(&decoded_meat_contract).unwrap();

    match meta_contract_args.to_enum() {
        MetaContractArgsUnion::CreateAccount(create_account) => {
            let script = create_account.script();
            let code_hash = hex::encode(script.as_reader().code_hash().raw_data());
            let hash_type = hex::encode(script.as_reader().hash_type().as_slice());
            let args = hex::encode(script.as_reader().args().raw_data());
            let fee = create_account.fee();
            let registry_id = fee.registry_id();
            let mut registry_id_buf = [0u8; 4];
            registry_id_buf.copy_from_slice(registry_id.as_slice());
            let amount = hex::encode(fee.amount().as_slice());
            (
                (code_hash, hash_type, args),
                (u32::from_le_bytes(registry_id_buf), amount)
            )
        }
         MetaContractArgsUnion::BatchCreateEthAccounts(batch_create_eth_accounts) => {
            let script = batch_create_eth_accounts.scripts().get(0).unwrap();
            let code_hash = hex::encode(script.as_reader().code_hash().raw_data());
            let hash_type = hex::encode(script.as_reader().hash_type().as_slice());
            let args = hex::encode(script.as_reader().args().raw_data());

            let fee = batch_create_eth_accounts.fee();
            let registry_id = fee.registry_id();
            let mut registry_id_buf = [0u8; 4];
            registry_id_buf.copy_from_slice(registry_id.as_slice());
            let amount = hex::encode(fee.amount().as_slice());

            (
                (code_hash, hash_type, args),
                (u32::from_le_bytes(registry_id_buf), amount)
            )
         }
    }
}

#[rustler::nif]
fn parse_global_state(arg: String) -> (u64, String, (u64, String), (u32, String), String) {
    let global_state = hex::decode(arg).unwrap();
    let molecule_global_state = GlobalState::from_slice(&global_state).unwrap();
    let finalized_block_number = molecule_global_state.last_finalized_block_number();
    let mut finalized_buf = [0u8; 8];
    finalized_buf.copy_from_slice(finalized_block_number.as_slice());
    let block_count = molecule_global_state.block().count();
    let block_merkle_root = molecule_global_state.block().merkle_root();
    let mut block_buf = [0u8; 8];
    block_buf.copy_from_slice(block_count.as_slice());
    let account_count = molecule_global_state.account().count();
    let account_merkle_root = molecule_global_state.account().merkle_root();
    let mut account_buf = [0u8; 4];
    account_buf.copy_from_slice(account_count.as_slice());
    let reverted_block_root = molecule_global_state.reverted_block_root();
    let status = molecule_global_state.status();

    // encode max params length is 7
    (
        u64::from_le_bytes(finalized_buf),
        hex::encode(reverted_block_root.as_slice()),
        (u64::from_le_bytes(block_buf), hex::encode(account_merkle_root.as_slice())),
        (u32::from_le_bytes(account_buf), hex::encode(block_merkle_root.as_slice())),
        hex::encode(status.as_slice())
    )
}

#[rustler::nif]
fn parse_v0_global_state(arg: String) -> (u64, String, (u64, String), (u32, String), String) {
    let global_state = hex::decode(arg).unwrap();
    let molecule_global_state = GlobalStateV0::from_slice(&global_state).unwrap();
    let finalized_block_number = molecule_global_state.last_finalized_block_number();
    let mut finalized_buf = [0u8; 8];
    finalized_buf.copy_from_slice(finalized_block_number.as_slice());
    let block_count = molecule_global_state.block().count();
    let block_merkle_root = molecule_global_state.block().merkle_root();
    let mut block_buf = [0u8; 8];
    block_buf.copy_from_slice(block_count.as_slice());
    let account_count = molecule_global_state.account().count();
    let account_merkle_root = molecule_global_state.account().merkle_root();
    let mut account_buf = [0u8; 4];
    account_buf.copy_from_slice(account_count.as_slice());
    let reverted_block_root = molecule_global_state.reverted_block_root();
    let status = molecule_global_state.status();

    // encode max params length is 7
    (
        u64::from_le_bytes(finalized_buf),
        hex::encode(reverted_block_root.as_slice()),
        (u64::from_le_bytes(block_buf), hex::encode(account_merkle_root.as_slice())),
        (u32::from_le_bytes(account_buf), hex::encode(block_merkle_root.as_slice())),
        hex::encode(status.as_slice())
    )
}

#[rustler::nif]
fn parse_deposition_lock_args(arg: String) -> (String, String) {
    let args = hex::decode(arg).unwrap();
    let deposition_args = DepositLockArgs::from_slice(&args[32..]).unwrap();
    let l2_lock_script = blake2b_256(deposition_args.layer2_lock().as_slice());
    let l1_lock_hash = deposition_args.owner_lock_hash();

    (hex::encode(l2_lock_script), hex::encode(l1_lock_hash.as_slice()))
}

#[rustler::nif]
fn parse_withdrawal_lock_args(arg: String) -> (String, (String, u64), String) {
    let args = hex::decode(arg).unwrap();
    let withdrawal_args = WithdrawalLockArgs::from_slice(&args[32..]).unwrap();
    let l2_script_hash = withdrawal_args.account_script_hash();
    let withdrawal_block_hash = withdrawal_args.withdrawal_block_hash();
    let block_number = withdrawal_args.withdrawal_block_number();
    let owner_lock_hash = withdrawal_args.owner_lock_hash();
    let mut block_buf = [0u8; 8];
    block_buf.copy_from_slice(block_number.as_slice());

    (
      hex::encode(l2_script_hash.as_slice()),
      (
        hex::encode(withdrawal_block_hash.as_slice()),
        u64::from_le_bytes(block_buf)
      ),
      hex::encode(owner_lock_hash.as_slice())
    )
}

#[rustler::nif]
fn parse_eth_address_registry_args(arg: String) -> (String, String, u64) {
    let args = hex::decode(arg).unwrap();
    let eth_addr_reg = ETHAddrRegArgs::from_slice(&args).unwrap();
    match eth_addr_reg.to_enum() {
        ETHAddrRegArgsUnion::EthToGw(eth_to_gw) => {
            (String::from("EthToGw"), hex::encode(eth_to_gw.as_slice()), 0)
        }
        ETHAddrRegArgsUnion::GwToEth(gw_to_eth) => {
            (String::from("GwToEth"), hex::encode(gw_to_eth.as_slice()), 0)
        }
        ETHAddrRegArgsUnion::SetMapping(set_mapping) => {
          let gw_script_hash = set_mapping.gw_script_hash();
          let mut fee_buf = [0u8; 8];
          let fee = set_mapping.fee();
          fee_buf.copy_from_slice(fee.as_slice());

          (String::from("SetMapping"), hex::encode(gw_script_hash.as_slice()), u64::from_le_bytes(fee_buf))
        }
        ETHAddrRegArgsUnion::BatchSetMapping(batch_set_mapping) => {
            let mut fee_buf = [0u8; 8];
            let gw_script_hashes = batch_set_mapping.gw_script_hashes();
            let fee = batch_set_mapping.fee();
            fee_buf.copy_from_slice(fee.as_slice());

            (String::from("BatchSetMapping"), hex::encode(gw_script_hashes.as_slice()), u64::from_le_bytes(fee_buf))
        }
    }
}
rustler::init!(
    "Elixir.Godwoken.MoleculeParser",
    [
        parse_meta_contract_args,
        parse_global_state,
        parse_v0_global_state,
        parse_deposition_lock_args,
        parse_withdrawal_lock_args,
        parse_eth_address_registry_args
    ]
);
