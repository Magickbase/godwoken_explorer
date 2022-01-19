defmodule GodwokenExplorer.DepositWithdrawalView do
  use GodwokenExplorer, :schema

  def list_by_script_hash(script_hash, page) do
    deposits = from(d in DepositHistory,
      join: u in UDT, on: u.id == d.udt_id,
      where: d.script_hash == ^script_hash,
      select: %{
         script_hash: d.script_hash,
         value: fragment("? / power(10, ?)::decimal", d.amount, u.decimal),
         udt_id: d.udt_id,
         layer1_block_number: d.layer1_block_number,
         layer1_tx_hash: d.layer1_tx_hash,
         layer1_output_index: d.layer1_output_index,
         ckb_lock_hash: d.ckb_lock_hash,
         timestamp: d.timestamp,
         udt_symbol: u.symbol,
         udt_name: u.name,
         udt_icon: u.icon,
         inserted_at: u.inserted_at,
         type: "deposit"
      }
      ) |> Repo.all()
    withdrawals = from(w in WithdrawalRequest,
      where: w.account_script_hash == ^script_hash,
      join: u in UDT, on: u.id == w.udt_id,
      join: u2 in UDT, on: u2.id == w.fee_udt_id,
      join: b3 in Block, on: b3.number == w.block_number,
      select: %{
        account_script_hash: w.account_script_hash,
        value: fragment("? / power(10, ?)::decimal", w.amount, u.decimal),
        capacity: w.capacity,
        owner_lock_hash: w.owner_lock_hash,
        payment_lock_hash: w.payment_lock_hash,
        sell_amount: fragment("? / power(10, ?)::decimal", w.sell_amount, u.decimal),
        sell_capacity: w.sell_capacity,
        fee_amount: fragment("? / power(10, ?)::decimal", w.fee_amount, u2.decimal),
        fee_udt_id: w.fee_udt_id,
        fee_udt_name: u2.name,
        fee_udt_symbol: u2.symbol,
        fee_udt_icon: u2.icon,
        sudt_script_hash: w.sudt_script_hash,
        udt_id: w.udt_id,
        udt_name: u.name,
        udt_symbol: u.symbol,
        udt_icon: u.icon,
        block_hash: w.block_hash,
        nonce: w.nonce,
        block_number: w.block_number,
        inserted_at: w.inserted_at,
        type: "withdrawal",
        timestamp: b3.timestamp
      }
      ) |> Repo.all()
    original_struct =
      (deposits ++ withdrawals)
      |> Enum.sort(&(&1.inserted_at > &2.inserted_at))
      |> Scrivener.paginate(%{page: page, page_size: 10})

    %{
      page: Integer.to_string(original_struct.page_number),
      total_count: Integer.to_string(original_struct.total_entries),
      txs: original_struct.entries
    }
  end
end
