defmodule GodwokenExplorer.WithdrawalHistoryView do
  use JSONAPI.View, type: "withdrawal_history"

  use GodwokenExplorer, :schema

  def fields do
    [:layer1_block_number, :layer1_tx_hash, :layer1_output_index, :l2_script_hash, :block_hash, :block_number, :udt_script_hash, :sell_amount, :sell_capacity, :owner_lock_hash, :payment_lock_hash, :amount, :udt_id, :timestamp, :state]
  end

  def relationships do
    [udt: {GodwokenExplorer.UDTView, :include}]
  end

  def find_by_owner_lock_hash(owner_lock_hash, page) do
    from(h in WithdrawalHistory,
      preload: [:udt],
      where:
        h.owner_lock_hash == ^owner_lock_hash, order_by: [desc: :id]
    )
    |> Repo.paginate(page: page)
  end
end
