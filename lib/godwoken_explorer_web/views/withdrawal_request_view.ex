defmodule GodwokenExplorer.WithdrawalRequestView do
  use JSONAPI.View, type: "withdrawal_request"
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [balance_to_view: 2]

  def fields do
    [
      :account_script_hash,
      :value,
      :ckb,
      :owner_lock_hash,
      :payment_lock_hash,
      :sell_value,
      :sell_ckb,
      :sudt_script_hash,
      :udt_id,
      :block_hash,
      :nonce,
      :block_number
    ]
  end

  def ckb(withdrawal_request, _connn) do
    balance_to_view(withdrawal_request.capacity, 8)
  end

  def sell_ckb(withdrawal_request, _connn) do
    balance_to_view(withdrawal_request.sell_capacity, 8)
  end

  def value(withdrawal_request, _connn) do
     balance_to_view(withdrawal_request.amount, UDT.get_decimal(withdrawal_request.udt_id))

  end

  def sell_value(withdrawal_request, _connn) do
     balance_to_view(withdrawal_request.sell_amount, UDT.get_decimal(withdrawal_request.udt_id))
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
