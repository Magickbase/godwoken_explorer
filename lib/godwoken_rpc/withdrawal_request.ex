defmodule GodwokenRPC.WithdrawalRequest do
  import GodwokenRPC.Util, only: [hex_to_number: 1]

  alias GodwokenExplorer.{UDT, Repo}

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
            "amount" => fee_amount,
          }
        },
        "signature" => _
      }) do

    udt_id =
      case Repo.get_by(UDT, script_hash: sudt_script_hash) do
        %UDT{id: udt_id} -> udt_id
        _ -> nil
      end

    %{
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
