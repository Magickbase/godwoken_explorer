defmodule GodwokenRPC.Transaction.FetchedReceipt do
  def request(tx_hash) do
    ExW3.tx_receipt(tx_hash)
  end
end
