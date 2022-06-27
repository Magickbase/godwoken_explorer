defmodule GodwokenRPC.WithdrawalRequest do
  import GodwokenRPC.Util, only: [hex_to_number: 1, transform_hex_number_to_le: 2]

  alias GodwokenExplorer.{UDT, Repo}
  alias Blake2.Blake2b

  def elixir_to_params(%{
        "block_hash" => block_hash,
        "block_number" => block_number,
        "raw" => %{
          "account_script_hash" => account_script_hash,
          "amount" => amount,
          "capacity" => capacity,
          "chain_id" => chain_id,
          "fee" => fee_amount,
          "nonce" => nonce,
          "sudt_script_hash" => sudt_script_hash,
          "owner_lock_hash" => owner_lock_hash,
          "registry_id" => registry_id
        },
        "signature" => _
      }) do
    udt_id =
      case Repo.get_by(UDT, script_hash: sudt_script_hash) do
        %UDT{id: udt_id} -> udt_id
        _ -> nil
      end

    molecule_raw =
      transform_hex_number_to_le(nonce, 4) <>
        transform_hex_number_to_le(chain_id, 8) <>
        transform_hex_number_to_le(capacity, 8) <>
        transform_hex_number_to_le(amount, 16) <>
        String.slice(sudt_script_hash, 2..-1) <>
        String.slice(account_script_hash, 2..-1) <>
        transform_hex_number_to_le(registry_id, 4) <>
        String.slice(owner_lock_hash, 2..-1) <>
        transform_hex_number_to_le(fee_amount, 16)

    hash =
      molecule_raw
      |> Base.decode16!(case: :lower)
      |> Blake2b.hash_hex("", 32, "", "ckb-default-hash")

    %{
      hash: "0x" <> hash,
      nonce: hex_to_number(nonce),
      capacity: hex_to_number(capacity),
      amount: hex_to_number(amount),
      sudt_script_hash: sudt_script_hash,
      account_script_hash: account_script_hash,
      owner_lock_hash: owner_lock_hash,
      fee_amount: hex_to_number(fee_amount),
      chain_id: hex_to_number(chain_id),
      registry_id: hex_to_number(registry_id),
      udt_id: udt_id,
      block_number: block_number,
      block_hash: block_hash,
      inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
      updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    }
  end
end
