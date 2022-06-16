defmodule GodwokenRPC.WithdrawalRequest do
  import GodwokenRPC.Util, only: [hex_to_number: 1, transform_hex_number_to_le: 2]

  alias GodwokenExplorer.{UDT, Repo}
  alias Blake2.Blake2b

  def elixir_to_params(%{
        "block_hash" => block_hash,
        "block_number" => block_number,
        "raw" => %{
          "nonce" => nonce,
          "capacity" => capacity,
          "amount" => amount,
          "sell_amount" => sell_amount,
          "sell_capacity" => sell_capacity,
          "sudt_script_hash" => sudt_script_hash,
          "account_script_hash" => account_script_hash,
          "owner_lock_hash" => owner_lock_hash,
          "payment_lock_hash" => payment_lock_hash,
          "fee" => %{
            "sudt_id" => fee_sudt_id,
            "amount" => fee_amount
          }
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
        transform_hex_number_to_le(capacity, 8) <>
        transform_hex_number_to_le(amount, 16) <>
        String.slice(sudt_script_hash, 2..-1) <>
        String.slice(account_script_hash, 2..-1) <>
        transform_hex_number_to_le(sell_amount, 16) <>
        transform_hex_number_to_le(sell_capacity, 8) <>
        String.slice(owner_lock_hash, 2..-1) <>
        String.slice(payment_lock_hash, 2..-1) <>
        transform_hex_number_to_le(fee_sudt_id, 4) <>
        transform_hex_number_to_le(fee_amount, 16)

    hash = Blake2b.hash_hex(molecule_raw, "", 32, "", "ckb-default-hash")

    %{
      hash: "0x" <> hash,
      nonce: hex_to_number(nonce),
      capacity: hex_to_number(capacity),
      amount: hex_to_number(amount),
      sell_amount: hex_to_number(sell_amount),
      sell_capacity: hex_to_number(sell_capacity),
      sudt_script_hash: sudt_script_hash,
      account_script_hash: account_script_hash,
      owner_lock_hash: owner_lock_hash,
      payment_lock_hash: payment_lock_hash,
      fee_udt_id: hex_to_number(fee_sudt_id),
      fee_amount: hex_to_number(fee_amount),
      udt_id: udt_id,
      block_number: block_number,
      block_hash: block_hash,
      inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
      updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    }
  end
end
