defmodule GodwokenExplorer.WithdrawalHistoryView do
  use JSONAPI.View, type: "withdrawal_history"
  use Retry

  use GodwokenExplorer, :schema

  def fields do
    [
      :layer1_block_number,
      :layer1_tx_hash,
      :layer1_output_index,
      :l2_script_hash,
      :block_hash,
      :block_number,
      :udt_script_hash,
      :owner_lock_hash,
      :amount,
      :udt_id,
      :timestamp,
      :state,
      :capacity
    ]
  end

  def layer1_tx_hash(withdrawal_history, _connn) do
    to_string(withdrawal_history.layer1_tx_hash)
  end

  def l2_script_hash(withdrawal_history, _connn) do
    to_string(withdrawal_history.l2_script_hash)
  end

  def block_hash(withdrawal_history, _connn) do
    to_string(withdrawal_history.block_hash)
  end

  def udt_script_hash(withdrawal_history, _connn) do
    to_string(withdrawal_history.udt_script_hash)
  end

  def owner_lock_hash(withdrawal_history, _connn) do
    to_string(withdrawal_history.owner_lock_hash)
  end

  def payment_lock_hash(withdrawal_history, _connn) do
    to_string(withdrawal_history.payment_lock_hash)
  end

  def relationships do
    [udt: {GodwokenExplorer.UDTView, :include}]
  end

  def find_by_l2_script_hash(l2_script_hash, page) do
    query_results = base_query(dynamic([h], h.l2_script_hash == ^l2_script_hash), page)

    if updated_state?(query_results) do
      base_query(dynamic([h], h.l2_script_hash == ^l2_script_hash), page)
    else
      query_results
    end
  end

  def find_by_owner_lock_hash(owner_lock_hash, page) do
    query_results = base_query(dynamic([h], h.owner_lock_hash == ^owner_lock_hash), page)

    if updated_state?(query_results) do
      base_query(dynamic([h], h.owner_lock_hash == ^owner_lock_hash), page)
    else
      query_results
    end
  end

  def updated_state?(query_results) do
    succeed_history_ids =
      query_results.entries
      |> Enum.filter(fn h -> h.state == :available end)
      |> Enum.map(fn h ->
        result =
          retry with: constant_backoff(500) |> Stream.take(3) do
            GodwokenRPC.fetch_live_cell(h.layer1_output_index, h.layer1_tx_hash)
          after
            result -> result
          else
            _error -> {:ok, true}
          end

        if !elem(result, 1) do
          h.id
        end
      end)
      |> Enum.filter(&(!is_nil(&1)))

    if length(succeed_history_ids) > 0 do
      from(h in WithdrawalHistory, where: h.id in ^succeed_history_ids)
      |> Repo.update_all(set: [state: :succeed])

      true
    else
      false
    end
  end

  defp base_query(condition, page) do
    from(h in WithdrawalHistory,
      preload: [:udt, [udt: :account]],
      where: ^condition,
      order_by: [desc: :id]
    )
    |> Repo.paginate(page: page)
  end
end
