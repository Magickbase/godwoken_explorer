mod generated;
pub use generated::packed;
use packed::MetaContractArgs;
use packed::CreateAccount;
use packed::GlobalState;
use packed::L2Block;
use packed::WitnessArgs;
use packed::DepositLockArgs;
use packed::WithdrawalLockArgs;
use packed::SUDTArgs;
use packed::SUDTArgsUnion;
use molecule::prelude::Entity;
use ckb_hash::blake2b_256;

mod atoms {
    rustler::atoms! {
        ok,
    }
}

// table CreateAccount {
//     script: Script,
//     fee: Fee,
// }
#[rustler::nif]
fn parse_meta_contract_args(arg: String) -> ((String, String, String), (u32, String))  {
    let sudt_transfer_args = hex::decode(arg).unwrap();
    let meta_contract_args = MetaContractArgs::from_slice(&sudt_transfer_args).unwrap().to_enum();
    let script = CreateAccount::from_slice(meta_contract_args.as_slice()).unwrap().script();
    let fee = CreateAccount::from_slice(meta_contract_args.as_slice()).unwrap().fee();
    let mut sudt_id = [0u8; 4];
    sudt_id.copy_from_slice(fee.sudt_id().as_slice());
    let amount = hex::encode(fee.amount().as_slice());
    let code_hash = hex::encode(script.as_reader().code_hash().raw_data());
    let hash_type = hex::encode(script.as_reader().hash_type().as_slice());
    let args = hex::encode(script.as_reader().args().raw_data());
    (
        (code_hash, hash_type, args),
        (u32::from_le_bytes(sudt_id), amount)
    )
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
fn parse_witness(arg: String) -> u64 {
    let witness = hex::decode(arg).unwrap();
    let l2_block_data = WitnessArgs::from_slice(&witness).unwrap().output_type().as_bytes();
    let l2_block_number = L2Block::from_slice(&l2_block_data[4..]).unwrap().raw().number();
    let mut buf = [0u8; 8];
    buf.copy_from_slice(l2_block_number.as_slice());

    u64::from_le_bytes(buf)
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
fn parse_withdrawal_lock_args(arg: String) -> (String, (String, u64), (String, String, u64), String, String) {
    let args = hex::decode(arg).unwrap();
    let withdrawal_args = WithdrawalLockArgs::from_slice(&args[32..]).unwrap();
    let l2_script_hash = withdrawal_args.account_script_hash();
    let withdrawal_block_hash = withdrawal_args.withdrawal_block_hash();
    let block_number = withdrawal_args.withdrawal_block_number();
    let mut block_buf = [0u8; 8];
    block_buf.copy_from_slice(block_number.as_slice());
    let sudt_script_hash = withdrawal_args.sudt_script_hash();
    let sell_amount = withdrawal_args.sell_amount();
    let sell_capacity = withdrawal_args.sell_capacity();
    let mut sell_capacity_buf = [0u8; 8];
    sell_capacity_buf.copy_from_slice(sell_capacity.as_slice());
    let owner_lock_hash = withdrawal_args.owner_lock_hash();
    let payment_lock_hash = withdrawal_args.payment_lock_hash();

    (
      hex::encode(l2_script_hash.as_slice()),
      (
        hex::encode(withdrawal_block_hash.as_slice()),
        u64::from_le_bytes(block_buf)
      ),
      (
        hex::encode(sudt_script_hash.as_slice()),
        hex::encode(sell_amount.as_slice()),
        u64::from_le_bytes(sell_capacity_buf)
      ),
      hex::encode(owner_lock_hash.as_slice()),
      hex::encode(payment_lock_hash.as_slice()),
    )
}

#[rustler::nif]
fn parse_sudt_transfer_args(arg: String) -> (String, String, String) {
    let sudt_transfer_args = hex::decode(arg).unwrap();
    let short_address = SUDTArgs::from_slice(&sudt_transfer_args).unwrap();
    match short_address.to_enum() {
        SUDTArgsUnion::SUDTTransfer(sudt_transfer) => {
            let mut to_address = [0u8; 20];
            to_address.copy_from_slice(&sudt_transfer.to().as_slice()[4..]);
            (
                hex::encode(to_address),
                hex::encode(sudt_transfer.amount().as_slice()),
                hex::encode(sudt_transfer.fee().as_slice()),
            )
        }
        SUDTArgsUnion::SUDTQuery(_sudt_query) => { (String::from("Godwoken"), String::from("Godwoken"), String::from("Godwoken"))  }
    }
}

rustler::init!(
    "Elixir.Godwoken.MoleculeParser",
    [
        parse_meta_contract_args,
        parse_global_state,
        parse_witness,
        parse_deposition_lock_args,
        parse_sudt_transfer_args,
        parse_withdrawal_lock_args
    ]
);
