defmodule GodwokenExplorer.DepositHistoryView do
  use JSONAPI.View, type: "deposit_history"
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [balance_to_view: 2]

  def fields do
    [
      :layer1_block_number,
      :layer1_tx_hash,
      :layer1_output_index,
      :value,
      :ckb_lock_hash,
      :timestamp,
      :capacity,
      :udt_id,
      :udt
    ]
  end

  def layer1_tx_hash(deposit_history, _conn) do
    to_string(deposit_history.layer1_tx_hash)
  end

  def ckb_lock_hash(deposit_history, _conn) do
    to_string(deposit_history.ckb_lock_hash)
  end

  def value(deposit_history, _conn) do
    balance_to_view(deposit_history.amount, deposit_history.udt.decimal || 0)
  end

  def udt(deposit_history, _conn) do
    address_hash =
      if deposit_history.udt.account != nil,
        do: to_string(deposit_history.udt.account.eth_address),
        else: nil

    %{
      eth_address: address_hash,
      name: deposit_history.udt.name,
      symbol: deposit_history.udt.symbol
    }
  end

  def list_by_script_hash(script_hash, page) do
    from(d in DepositHistory,
      preload: [:udt, [udt: :account]],
      where: d.script_hash == ^script_hash,
      order_by: [desc: :id]
    )
    |> Repo.paginate(page: page)
  end
end
