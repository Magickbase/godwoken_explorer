defmodule GodwokenExplorer.DepositWithdrawalView do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [balance_to_view: 2]

  alias GodwokenExplorer.UDT

  @export_limit 5_000

  def list_by_block_number(block_number, page) do
    if is_nil(page) do
      withdrawal_base_query(dynamic([w], w.block_number == ^block_number))
      |> order_by(desc: :inserted_at)
      |> limit(@export_limit)
      |> Repo.all()
      |> Enum.map(fn struct ->
        struct
        |> Map.merge(%{
          value: balance_to_view(struct[:value], struct[:udt_decimal] || 0)
        })
      end)
    else
      parsed_struct =
        withdrawal_base_query(dynamic([w], w.block_number == ^block_number))
        |> order_by(desc: :inserted_at)
        |> Repo.paginate(page: page)

      parsed_entries =
        parsed_struct.entries
        |> Enum.map(fn struct ->
          struct
          |> Map.merge(%{
            value: balance_to_view(struct[:value], struct[:udt_decimal] || 0)
          })
        end)

      %{
        page: parsed_struct.page_number,
        total_count: parsed_struct.total_entries,
        data: parsed_entries
      }
    end
  end

  def list_by_udt_id(udt_id, page) do
    deposits = deposit_base_query(dynamic([d], d.udt_id == ^udt_id))

    withdrawals = withdrawal_base_query(dynamic([w], w.udt_id == ^udt_id))

    original_struct =
      from(q in subquery(deposits |> union_all(^withdrawals)), order_by: [desc: q.timestamp])

    parse_struct(original_struct, page)
  end

  def list_by_script_hash(script_hash, page) do
    deposits = deposit_base_query(dynamic([d], d.script_hash == ^script_hash))
    withdrawals = withdrawal_base_query(dynamic([w], w.l2_script_hash == ^script_hash))

    original_struct =
      from(q in subquery(deposits |> union_all(^withdrawals)), order_by: [desc: q.timestamp])

    parse_struct(original_struct, page)
  end

  @spec parse_struct(any, any) :: %{data: any, page: binary, total_count: binary}
  def parse_struct(original_struct, page) do
    if is_nil(page) do
      original_struct
      |> limit(@export_limit)
      |> Repo.all()
      |> Enum.map(fn struct ->
        value =
          if struct[:udt_id] == UDT.ckb_account_id() do
            0
          else
            balance_to_view(struct[:value], struct[:udt_decimal] || 0)
          end

        struct
        |> Map.merge(%{
          value: value
        })
      end)
    else
      parsed_struct = Repo.paginate(original_struct, page: page)

      parsed_entries =
        parsed_struct.entries
        |> Enum.map(fn struct ->
          value =
            if struct[:udt_id] == UDT.ckb_account_id() do
              0
            else
              balance_to_view(struct[:value], struct[:udt_decimal] || 0)
            end

          struct
          |> Map.merge(%{
            value: value
          })
        end)

      %{
        page: Integer.to_string(parsed_struct.page_number),
        total_count: Integer.to_string(parsed_struct.total_entries),
        data: parsed_entries
      }
    end
  end

  def withdrawal_base_query(condition) do
    from(w in WithdrawalHistory,
      join: u in UDT,
      on: u.id == w.udt_id,
      join: a2 in Account,
      on: a2.script_hash == w.l2_script_hash,
      where: ^condition,
      select: %{
        script_hash: fragment("'0x' || encode(?, 'hex')", w.l2_script_hash),
        eth_address: fragment("'0x' || encode(?, 'hex')", a2.eth_address),
        value: w.amount,
        owner_lock_hash: fragment("'0x' || encode(?, 'hex')", w.owner_lock_hash),
        sudt_script_hash: fragment("'0x' || encode(?, 'hex')", w.udt_script_hash),
        udt_id: w.udt_id,
        udt_name: u.name,
        udt_symbol: u.symbol,
        udt_icon: u.icon,
        udt_decimal: u.decimal,
        block_hash: fragment("'0x' || encode(?, 'hex')", w.block_hash),
        block_number: w.block_number,
        timestamp: w.timestamp,
        layer1_block_number: w.layer1_block_number,
        layer1_tx_hash: fragment("'0x' || encode(?, 'hex')", w.layer1_tx_hash),
        layer1_output_index: w.layer1_output_index,
        ckb_lock_hash: nil,
        state: w.state,
        type: "withdrawal",
        capacity: w.capacity
      }
    )
  end

  def deposit_base_query(condition) do
    from(d in DepositHistory,
      join: u in UDT,
      on: u.id == d.udt_id,
      join: a2 in Account,
      on: a2.script_hash == d.script_hash,
      where: ^condition,
      select: %{
        script_hash: fragment("'0x' || encode(?, 'hex')", d.script_hash),
        eth_address: fragment("'0x' || encode(?, 'hex')", a2.eth_address),
        value: d.amount,
        owner_lock_hash: nil,
        sudt_script_hash: nil,
        udt_id: d.udt_id,
        udt_name: u.name,
        udt_symbol: u.symbol,
        udt_icon: u.icon,
        udt_decimal: u.decimal,
        block_hash: nil,
        block_number: nil,
        timestamp: d.timestamp,
        layer1_block_number: d.layer1_block_number,
        layer1_tx_hash: fragment("'0x' || encode(?, 'hex')", d.layer1_tx_hash),
        layer1_output_index: d.layer1_output_index,
        ckb_lock_hash: fragment("'0x' || encode(?, 'hex')", d.ckb_lock_hash),
        state: "succeed",
        type: "deposit",
        capacity: d.capacity
      }
    )
  end
end
