defmodule Godwoken.MoleculeParser do
    use Rustler, otp_app: :godwoken_explorer, crate: :molecule_parser

    # When your NIF is loaded, it will override this function.
    def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
    def parse_meta_contract_args(_a), do: :erlang.nif_error(:nif_not_loaded)
    def parse_global_state(_a), do: :erlang.nif_error(:nif_not_loaded)
    def parse_witness(_a), do: :erlang.nif_error(:nif_not_loaded)
    def parse_deposition_lock_args(_a), do: :erlang.nif_error(:nif_not_loaded)
end
