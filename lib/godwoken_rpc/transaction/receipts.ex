defmodule GodwokenRPC.Transaction.Receipts do
  import GodwokenRPC, only: [request: 1]
  import GodwokenRPC.HTTP, only: [json_rpc: 2]
  import GodwokenRPC.Util, only: [parse_gw_address: 1, parse_le_number: 1]

  alias GodwokenRPC.Transaction.Receipt

  def fetch(transaction_hashes, options) when is_list(transaction_hashes) do
    {requests, id_to_transaction_params} =
      transaction_hashes
      |> Stream.with_index()
      |> Enum.reduce({[], %{}}, fn {%{hash: transaction_hash} = transaction_params, id},
                                   {acc_requests, acc_id_to_transaction_params} ->
        requests = [request(id, transaction_hash) | acc_requests]
        id_to_transaction_params = Map.put(acc_id_to_transaction_params, id, transaction_params)
        {requests, id_to_transaction_params}
      end)

    with {:ok, responses} <- json_rpc(requests, options),
         {:ok, receipts} <- reduce_responses(responses, id_to_transaction_params) do
      elixir_receipts = to_elixir(receipts)
      elixir_logs = elixir_to_logs(elixir_receipts)
      sudt_transfers = filter_sudt_transfers(elixir_logs)
      sudt_pay_fees = filter_sudt_pay_fees(elixir_logs)

      {:ok, %{logs: elixir_logs, sudt_transfers: sudt_transfers, sudt_pay_fees: sudt_pay_fees}}
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

  defp response_to_receipt(%{id: id, result: receipt}, id_to_transaction_params) do
    {:ok,
     receipt
     |> Map.merge(%{"transaction_hash" => id_to_transaction_params |> get_in([id, :hash])})}
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

  defp filter_sudt_transfers(elixir_logs) do
    elixir_logs
    |> Enum.filter(fn log -> log[:type] == :sudt_transfer end)
    |> Enum.map(fn log ->
      {{from_registry_id, from_address}, {to_registry_id, to_address}, amount} =
        parse_log_data(log[:data])

      %{
        transaction_hash: log[:transaction_hash],
        log_index: log[:index],
        udt_id: log[:account_id],
        from_address: from_address,
        to_address: to_address,
        amount: amount,
        from_registry_id: from_registry_id,
        to_registry_id: to_registry_id
      }
    end)
  end

  defp filter_sudt_pay_fees(elixir_logs) do
    elixir_logs
    |> Enum.filter(fn log -> log[:type] == :sudt_pay_fee end)
    |> Enum.map(fn log ->
      {{from_registry_id, from_address}, {block_producer_registry_id, block_producer_address},
       amount} = parse_log_data(log[:data])

      %{
        transaction_hash: log[:transaction_hash],
        log_index: log[:index],
        udt_id: log[:account_id],
        from_address: from_address,
        block_producer_address: block_producer_address,
        amount: amount,
        from_registry_id: from_registry_id,
        block_producer_registry_id: block_producer_registry_id
      }
    end)
  end

  # data format should be from_registry_address + to_registry_address + amount
  # registry address format: 4 bytes registry id(u32) in little endian, 4 bytes address byte size(u32) in little endian, and 0 or 20 bytes address
  # registry address can be 8-bytes(empty address) or 28-bytes(eth address)
  # amount is a u256 number in little endian format
  # so data can be (8 + 8 + 32) or (8 + 28 + 32) or (28 + 8 + 32) or (28 + 28 + 32) bytes
  def parse_log_data(data) do
    {from_registry_id, from_address} = data |> String.slice(2, 56) |> parse_gw_address()
    to_start = if from_address == "0x", do: 18, else: 58
    {to_registry_id, to_address} = data |> String.slice(to_start, 56) |> parse_gw_address()
    amount_start = if to_address == "0x", do: to_start + 16, else: to_start + 56

    amount = data |> String.slice(amount_start..-1) |> parse_le_number()
    {{from_registry_id, from_address}, {to_registry_id, to_address}, amount}
  end
end
