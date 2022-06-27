defmodule Godwoken.MoleculeParser do
  use Rustler, otp_app: :godwoken_explorer, crate: :molecule_parser

  def parse_meta_contract_args(_a), do: :erlang.nif_error(:nif_not_loaded)
  def parse_global_state(_a), do: :erlang.nif_error(:nif_not_loaded)
  def parse_v0_global_state(_a), do: :erlang.nif_error(:nif_not_loaded)
  def parse_deposition_lock_args(_a), do: :erlang.nif_error(:nif_not_loaded)
  def parse_v1_deposition_lock_args(_a), do: :erlang.nif_error(:nif_not_loaded)
  def parse_withdrawal_lock_args(_a), do: :erlang.nif_error(:nif_not_loaded)
  def parse_eth_address_registry_args(_a), do: :erlang.nif_error(:nif_not_loaded)
end
