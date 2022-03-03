defmodule GodwokenRPC.WithdrawalRequest do
  import GodwokenRPC.Util, only: [hex_to_number: 1]

  alias GodwokenExplorer.{UDT, Repo}

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
          "owner_lock_hash" => owner_lock_hash
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
      sudt_script_hash: sudt_script_hash,
      account_script_hash: account_script_hash,
      owner_lock_hash: owner_lock_hash,
      fee_amount: hex_to_number(fee_amount),
      chain_id: hex_to_number(chain_id),
      udt_id: udt_id,
      block_number: block_number,
      block_hash: block_hash,
      inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
      updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    }
  end
end
