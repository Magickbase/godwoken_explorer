use rustler::{Encoder, Env, Error, Term};
use std::str;
mod molecule_type;
use molecule_type::MetaContractArgs;
use molecule_type::CreateAccount;
use molecule::prelude::Entity;

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
        ("parse_meta_contract_args", 1, parse_meta_contract_args)
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
