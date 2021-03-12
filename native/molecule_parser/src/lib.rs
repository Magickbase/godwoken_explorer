use rustler::{Encoder, Env, Error, Term};
use std::str;

mod generated;
pub use generated::packed;
use packed::MetaContractArgs;
use packed::CreateAccount;
use packed::GlobalState;
use packed::L2Block;
use packed::WitnessArgs;
use packed::DepositionLockArgs;
use molecule::prelude::Entity;
use ckb_hash::blake2b_256;

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        //atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

rustler::rustler_export_nifs! {
    "Elixir.Godwoken.MoleculeParser",
    [
        ("parse_meta_contract_args", 1, parse_meta_contract_args),
        ("parse_global_state", 1, parse_global_state),
        ("parse_witness", 1, parse_witness),
        ("parse_deposition_lock_args", 1, parse_deposition_lock_args)
    ],
    None
}

fn parse_meta_contract_args<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let hex_string: &str = args[0].decode()?;
    let sudt_transfer_args = hex::decode(hex_string).unwrap();
    let meta_contract_args = MetaContractArgs::from_slice(&sudt_transfer_args).unwrap().to_enum();
    // let create_account_args: Vec<u8> = vec![];
    // create_account_args.copy_from_slice(&meta_contract_args);
    let script = CreateAccount::from_slice(meta_contract_args.as_slice()).unwrap().script();
    let code_hash = hex::encode(script.as_reader().code_hash().raw_data());
    let hash_type = hex::encode(script.as_reader().hash_type().as_slice());
    let args = hex::encode(script.as_reader().args().raw_data());

    Ok((atoms::ok(), code_hash, hash_type, args).encode(env))
}

fn parse_global_state<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let hex_string: &str = args[0].decode()?;
    let global_state = hex::decode(hex_string).unwrap();
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
    Ok((
        atoms::ok(),
        u64::from_le_bytes(finalized_buf),
        hex::encode(reverted_block_root.as_slice()),
        (u64::from_le_bytes(block_buf),
        hex::encode(account_merkle_root.as_slice())),
        (u32::from_le_bytes(account_buf),
        hex::encode(block_merkle_root.as_slice())),
        hex::encode(status.as_slice())
    ).encode(env))
}

fn parse_witness<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let hex_string: &str = args[0].decode()?;
    let witness = hex::decode(hex_string).unwrap();
    let l2_block_data = WitnessArgs::from_slice(&witness).unwrap().output_type().as_bytes();
    let l2_block_number = L2Block::from_slice(&l2_block_data[4..]).unwrap().raw().number();
    let mut buf = [0u8; 8];
    buf.copy_from_slice(l2_block_number.as_slice());

    Ok((atoms::ok(), u64::from_le_bytes(buf)).encode(env))
}

fn parse_deposition_lock_args<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let hex_string: &str = args[0].decode()?;
    let args = hex::decode(hex_string).unwrap();
    let deposition_args = DepositionLockArgs::from_slice(&args[32..]).unwrap();
    let l2_lock_script = blake2b_256(deposition_args.layer2_lock().as_slice());
    let l1_lock_hash = deposition_args.owner_lock_hash();

    Ok((atoms::ok(), hex::encode(l2_lock_script), hex::encode(l1_lock_hash.as_slice())).encode(env))
}
