defmodule GodwokenExplorer.DepositWithdrawalView do
  use GodwokenExplorer, :schema

  def list_by_block_number(block_number, page) do
    parsed_struct =
      withdrawal_base_query(dynamic([w], w.block_number == ^block_number))
      |> order_by(desc: :inserted_at)
      |> Repo.paginate(page: page)

    %{
      page: Integer.to_string(parsed_struct.page_number),
      total_count: Integer.to_string(parsed_struct.total_entries),
      data: parsed_struct.entries
    }
  end

  def list_by_udt_id(udt_id, page) do
    deposits = GodwokenExplorer.DepositWithdrawalView.deposit_base_query(dynamic([d], d.udt_id == ^udt_id))
    withdrawals = GodwokenExplorer.DepositWithdrawalView.withdrawal_base_query(dynamic([w], w.udt_id == ^udt_id))
    original_struct = from(q in subquery(deposits |> union_all(^withdrawals)), order_by: [desc: q.timestamp])

    parse_struct(original_struct, page)
  end

  def list_by_script_hash(script_hash, page) do
    deposits = deposit_base_query(dynamic([d], d.script_hash == ^script_hash))
    withdrawals = withdrawal_base_query(dynamic([w], w.account_script_hash == ^script_hash))
    original_struct = from(q in subquery(deposits |> union_all(^withdrawals)), order_by: [desc: q.timestamp])

    parse_struct(original_struct, page)
  end

  @spec parse_struct(any, any) :: %{data: any, page: binary, total_count: binary}
  def parse_struct(original_struct, page) do
    parsed_struct = Repo.paginate(original_struct, page: page)

    %{
      page: Integer.to_string(parsed_struct.page_number),
      total_count: Integer.to_string(parsed_struct.total_entries),
      data: parsed_struct.entries
    }
  end

  def withdrawal_base_query(condition) do
    from(w in WithdrawalRequest,
      join: u in UDT,
      on: u.id == w.udt_id,
      join: u2 in UDT,
      on: u2.id == w.fee_udt_id,
      join: b3 in Block,
      on: b3.number == w.block_number,
      where: ^condition,
      select: %{
        script_hash: w.account_script_hash,
        value: fragment("? / power(10, ?)::decimal", w.amount, u.decimal),
        capacity: w.capacity,
        owner_lock_hash: w.owner_lock_hash,
        payment_lock_hash: w.payment_lock_hash,
        sell_value: fragment("? / power(10, ?)::decimal", w.sell_amount, u.decimal),
        sell_capacity: w.sell_capacity,
        fee_value: fragment("? / power(10, ?)::decimal", w.fee_amount, u2.decimal),
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
        type: "withdrawal",
        timestamp: b3.timestamp,
        layer1_block_number: nil,
        layer1_tx_hash: nil,
        layer1_output_index: nil,
        ckb_lock_hash: nil
      }
    )
  end

  def deposit_base_query(condition) do
    from(d in DepositHistory,
      join: u in UDT,
      on: u.id == d.udt_id,
      where: ^condition,
      select: %{
        script_hash: d.script_hash,
        value: fragment("? / power(10, ?)::decimal", d.amount, u.decimal),
        capacity: nil,
        owner_lock_hash: nil,
        payment_lock_hash: nil,
        sell_value: nil,
        sell_capacity: nil,
        fee_value: nil,
        fee_udt_id: nil,
        fee_udt_name: nil,
        fee_udt_symbol: nil,
        fee_udt_icon: nil,
        sudt_script_hash: nil,
        udt_id: d.udt_id,
        udt_name: u.name,
        udt_symbol: u.symbol,
        udt_icon: u.icon,
        block_hash: nil,
        nonce: nil,
        block_number: nil,
        type: "deposit",
        timestamp: d.timestamp,
        layer1_block_number: d.layer1_block_number,
        layer1_tx_hash: d.layer1_tx_hash,
        layer1_output_index: d.layer1_output_index,
        ckb_lock_hash: d.ckb_lock_hash
      }
    )
  end
end
