defmodule GodwokenExplorer.DepositHistoryView do
  use JSONAPI.View, type: "deposit_history"
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [balance_to_view: 2]

  def fields do
    [:layer1_block_number, :layer1_tx_hash, :layer1_output_index, :udt_id, :value, :ckb_lock_hash, :timestamp]
  end

  def relationships do
    [udt: {GodwokenExplorer.UDTView, :include}]
  end

  def value(deposit_history, _conn) do
    balance_to_view(deposit_history.amount, UDT.get_decimal(deposit_history.udt_id))
  end

  def list_by_script_hash(script_hash, page) do
    from(d in DepositHistory,
      preload: [:udt, [udt: :account]],
      where: d.script_hash == ^script_hash,
      order_by: [desc: :id])
    |> Repo.paginate(page: page)
  end
end
