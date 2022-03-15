defmodule GodwokenRPC.Receipts do
  @moduledoc """
  Receipts format as returned by
  [`eth_getTransactionReceipt`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionreceipt) from batch
  requests.
  """

  import GodwokenRPC, only: [request: 1]
  import GodwokenRPC.HTTP, only: [json_rpc: 2]

  alias GodwokenRPC.{Logs, Receipt}

  @type elixir :: [Receipt.elixir()]
  @type t :: [Receipt.t()]

  @doc """
  Extracts logs from `t:elixir/0`

      iex> GodwokenRPC.Receipts.elixir_to_logs([
      ...>   %{
      ...>     "blockHash" => "0xf6b4b8c88df3ebd252ec476328334dc026cf66606a84fb769b3d3cbccc8471bd",
      ...>     "blockNumber" => 37,
      ...>     "contractAddress" => nil,
      ...>     "cumulativeGasUsed" => 50450,
      ...>     "gasUsed" => 50450,
      ...>     "logs" => [
      ...>       %{
      ...>         "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
      ...>         "blockHash" => "0xf6b4b8c88df3ebd252ec476328334dc026cf66606a84fb769b3d3cbccc8471bd",
      ...>         "blockNumber" => 37,
      ...>         "data" => "0x000000000000000000000000862d67cb0773ee3f8ce7ea89b328ffea861ab3ef",
      ...>         "logIndex" => 0,
      ...>         "topics" => ["0x600bcf04a13e752d1e3670a5a9f1c21177ca2a93c6f5391d4f1298d098097c22"],
      ...>         "transactionHash" => "0x53bd884872de3e488692881baeec262e7b95234d3965248c39fe992fffd433e5",
      ...>         "transactionIndex" => 0,
      ...>         "transactionLogIndex" => 0,
      ...>         "type" => "mined"
      ...>       }
      ...>     ],
      ...>     "logsBloom" => "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000200000000000000000000020000000000000000200000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      ...>     "root" => nil,
      ...>     "status" => :ok,
      ...>     "transactionHash" => "0x53bd884872de3e488692881baeec262e7b95234d3965248c39fe992fffd433e5",
      ...>     "transactionIndex" => 0
      ...>   }
      ...> ])
      [
        %{
          "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
          "blockHash" => "0xf6b4b8c88df3ebd252ec476328334dc026cf66606a84fb769b3d3cbccc8471bd",
          "blockNumber" => 37,
          "data" => "0x000000000000000000000000862d67cb0773ee3f8ce7ea89b328ffea861ab3ef",
          "logIndex" => 0,
          "topics" => ["0x600bcf04a13e752d1e3670a5a9f1c21177ca2a93c6f5391d4f1298d098097c22"],
          "transactionHash" => "0x53bd884872de3e488692881baeec262e7b95234d3965248c39fe992fffd433e5",
          "transactionIndex" => 0,
          "transactionLogIndex" => 0,
          "type" => "mined"
        }
      ]

  """
  @spec elixir_to_logs(elixir) :: Logs.elixir()
  def elixir_to_logs(elixir) when is_list(elixir) do
    Enum.flat_map(elixir, &Receipt.elixir_to_logs/1)
  end

  @doc """
  Converts each element of `t:elixir/0` to params used by `Explorer.Chain.Receipt.changeset/2`.

      iex> GodwokenRPC.Receipts.elixir_to_params([
      ...>   %{
      ...>     "blockHash" => "0xf6b4b8c88df3ebd252ec476328334dc026cf66606a84fb769b3d3cbccc8471bd",
      ...>     "blockNumber" => 37,
      ...>     "contractAddress" => nil,
      ...>     "cumulativeGasUsed" => 50450,
      ...>     "gasUsed" => 50450,
      ...>     "logs" => [
      ...>       %{
      ...>         "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
      ...>         "blockHash" => "0xf6b4b8c88df3ebd252ec476328334dc026cf66606a84fb769b3d3cbccc8471bd",
      ...>         "blockNumber" => 37,
      ...>         "data" => "0x000000000000000000000000862d67cb0773ee3f8ce7ea89b328ffea861ab3ef",
      ...>         "logIndex" => 0,
      ...>         "topics" => ["0x600bcf04a13e752d1e3670a5a9f1c21177ca2a93c6f5391d4f1298d098097c22"],
      ...>         "transactionHash" => "0x53bd884872de3e488692881baeec262e7b95234d3965248c39fe992fffd433e5",
      ...>         "transactionIndex" => 0,
      ...>         "transactionLogIndex" => 0,
      ...>         "type" => "mined"
      ...>       }
      ...>     ],
      ...>     "logsBloom" => "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000200000000000000000000020000000000000000200000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      ...>     "root" => nil,
      ...>     "status" => :ok,
      ...>     "transactionHash" => "0x53bd884872de3e488692881baeec262e7b95234d3965248c39fe992fffd433e5",
      ...>     "transactionIndex" => 0
      ...>   }
      ...> ])
      [
        %{
          created_contract_address_hash: nil,
          cumulative_gas_used: 50450,
          gas_used: 50450,
          status: :ok,
          transaction_hash: "0x53bd884872de3e488692881baeec262e7b95234d3965248c39fe992fffd433e5",
          transaction_index: 0
        }
      ]

  """
  @spec elixir_to_params(elixir) :: [map]
  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.map(elixir, &Receipt.elixir_to_params/1)
  end

  def fetch(transactions_params, options) when is_list(transactions_params) do
    {requests, id_to_transaction_params} =
      transactions_params
      |> Stream.with_index()
      |> Enum.reduce({[], %{}}, fn {%{eth_hash: transaction_hash} = transaction_params, id},
                                   {acc_requests, acc_id_to_transaction_params} ->
        requests = [request(id, transaction_hash) | acc_requests]
        id_to_transaction_params = Map.put(acc_id_to_transaction_params, id, transaction_params)
        {requests, id_to_transaction_params}
      end)

    with {:ok, responses} <- json_rpc(requests, options),
         {:ok, receipts} <- reduce_responses(responses, id_to_transaction_params) do
      elixir_receipts = to_elixir(receipts)

      elixir_logs = elixir_to_logs(elixir_receipts)
      receipts = elixir_to_params(elixir_receipts)
      logs = Logs.elixir_to_params(elixir_logs)

      {:ok, %{logs: logs, receipts: receipts}}
    end
  end

  def put(transactions_params, receipts_params) when is_list(transactions_params) and is_list(receipts_params) do
    transaction_hash_to_receipt_params =
      Enum.into(receipts_params, %{}, fn %{transaction_hash: transaction_hash} = receipt_params ->
        {transaction_hash, receipt_params}
      end)

    Enum.map(transactions_params, fn %{eth_hash: transaction_hash} = transaction_params ->
      receipts_params = Map.fetch!(transaction_hash_to_receipt_params, transaction_hash)
      merged_params = Map.merge(transaction_params, receipts_params)

      if transaction_params[:created_contract_address_hash] && is_nil(receipts_params[:created_contract_address_hash]) do
        Map.put(merged_params, :created_contract_address_hash, transaction_params[:created_contract_address_hash])
      else
        merged_params
      end
    end)
  end

  def to_elixir(receipts) when is_list(receipts) do
    Enum.map(receipts, &Receipt.to_elixir/1)
  end

  defp request(id, transaction_hash) when is_integer(id) and is_binary(transaction_hash) do
    request(%{
      id: id,
      method: "eth_getTransactionReceipt",
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
  defp reduce_receipt({:error, reason}, {:error, reasons}) when is_list(reasons), do: {:error, [reason | reasons]}
end
