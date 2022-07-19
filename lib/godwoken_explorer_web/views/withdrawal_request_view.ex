defmodule GodwokenExplorer.WithdrawalRequestView do
  use JSONAPI.View, type: "withdrawal_request"
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [balance_to_view: 2]

  def fields do
    [
      :account_script_hash,
      :value,
      :capacity,
      :owner_lock_hash,
      :sudt_script_hash,
      :udt_id,
      :block_hash,
      :nonce,
      :block_number
    ]
  end

  def account_script_hash(withdrawal_request, _connn) do
    to_string(withdrawal_request.account_script_hash)
  end

  def block_hash(withdrawal_request, _connn) do
    to_string(withdrawal_request.block_hash)
  end

  def sudt_script_hash(withdrawal_request, _connn) do
    to_string(withdrawal_request.sudt_script_hash)
  end

  def owner_lock_hash(withdrawal_request, _connn) do
    to_string(withdrawal_request.owner_lock_hash)
  end

  def value(withdrawal_request, _connn) do
    balance_to_view(withdrawal_request.amount, UDT.get_decimal(withdrawal_request.udt_id) || 0)
  end

  def relationships do
    [udt: {GodwokenExplorer.UDTView, :include}]
  end

  def list_by_script_hash(l2_script_hash, page) do
    from(wr in WithdrawalRequest,
      preload: [:udt, [udt: :account]],
      where: wr.account_script_hash == ^l2_script_hash,
      order_by: [desc: :id]
    )
    |> Repo.paginate(page: page)
  end
end
