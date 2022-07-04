defmodule GodwokenRPC.Transaction.Receipts do
  import GodwokenRPC, only: [request: 1]
  import GodwokenRPC.HTTP, only: [json_rpc: 2]

  alias GodwokenRPC.Transaction.Receipt

  def fetch(transaction_hashes, options) when is_list(transaction_hashes) do
    {requests, id_to_transaction_params} =
      transaction_hashes
      |> Stream.with_index()
      |> Enum.reduce({[], %{}}, fn {%{gw_hash: transaction_hash} = transaction_params, id},
                                   {acc_requests, acc_id_to_transaction_params} ->
        requests = [request(id, transaction_hash) | acc_requests]
        id_to_transaction_params = Map.put(acc_id_to_transaction_params, id, transaction_params)
        {requests, id_to_transaction_params}
      end)

    with {:ok, responses} <- json_rpc(requests, options),
         {:ok, receipts} <- reduce_responses(responses, id_to_transaction_params) do
      elixir_receipts = to_elixir(receipts)
      elixir_logs = elixir_to_logs(elixir_receipts)

      {:ok, %{logs: elixir_logs}}
    end
  end

  def elixir_to_logs(elixir) when is_list(elixir) do
    Enum.flat_map(elixir, &Receipt.elixir_to_logs/1)
  end

  def to_elixir(receipts) when is_list(receipts) do
    Enum.map(receipts, &Receipt.to_elixir/1)
  end

  defp request(id, transaction_hash) when is_integer(id) and is_binary(transaction_hash) do
    request(%{
      id: id,
      method: "gw_get_transaction_receipt",
      params: [transaction_hash]
    })
  end

  defp response_to_receipt(%{id: id, result: nil}, id_to_transaction_params) do
    data = Map.fetch!(id_to_transaction_params, id)
    {:error, %{code: -32602, data: data, message: "Not Found"}}
  end

  defp response_to_receipt(%{id: _id, result: receipt}, _id_to_transaction_params) do
    # gas from the transaction is needed for pre-Byzantium derived status
    {:ok, receipt}
  end

  defp response_to_receipt(%{id: id, error: reason}, id_to_transaction_params) do
    data = Map.fetch!(id_to_transaction_params, id)
    annotated_reason = Map.put(reason, :data, data)
    {:error, annotated_reason}
  end

  defp reduce_responses(responses, id_to_transaction_params)
       when is_list(responses) and is_map(id_to_transaction_params) do
    responses
    |> Stream.map(&response_to_receipt(&1, id_to_transaction_params))
    |> Enum.reduce({:ok, []}, &reduce_receipt(&1, &2))
  end

  defp reduce_receipt({:ok, receipt}, {:ok, receipts}) when is_list(receipts),
    do: {:ok, [receipt | receipts]}

  defp reduce_receipt({:ok, _}, {:error, _} = error), do: error
  defp reduce_receipt({:error, reason}, {:ok, _}), do: {:error, [reason]}

  defp reduce_receipt({:error, reason}, {:error, reasons}) when is_list(reasons),
    do: {:error, [reason | reasons]}
end
