defmodule GodwokenRPC do
  import GodwokenRPC.Util, only: [hex_to_number: 1]

  require Logger

  alias GodwokenRPC.{Blocks, Block, HTTP}
  alias GodwokenRPC.CKBIndexer.{FetchedTransactions, FetchedTransaction, FetchedTip}
  alias GodwokenRPC.Account.FetchedAccountID

  def request(%{method: method, params: params} = map)
      when is_binary(method) and is_list(params) do
    Map.put(map, :jsonrpc, "2.0")
  end

  def request(%{method: method} = map)
      when is_binary(method) do
    Map.put(map, :jsonrpc, "2.0")
  end

  def fetch_blocks_by_range(_first.._last = range) do
    range
    |> Enum.map(fn number -> %{number: number} end)
    |> fetch_blocks_by_params(&Block.ByNumber.request/1)
  end

  defp fetch_blocks_by_params(params, request)
       when is_list(params) and is_function(request, 1) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> Blocks.requests(request)
           |> HTTP.json_rpc(options) do
      {:ok, Blocks.from_responses(responses, id_to_params)}
    end
  end

  def fetch_l1_tip_block_nubmer do
    indexer_options = Application.get_env(:godwoken_explorer, :ckb_indexer_named_arguments)
    case FetchedTip.request() |> HTTP.json_rpc(indexer_options) do
      {:ok, %{"block_number" => l1_tip_block_number}} -> {:ok, hex_to_number(l1_tip_block_number)}
      {:error, msg} ->
        Logger.error(fn -> ["Failed to request L1 tip block number: ", msg] end)
        {:error, msg}
    end
  end

  def fetch_l1_txs_by_range(params) do
    indexer_options = Application.get_env(:godwoken_explorer, :ckb_indexer_named_arguments)
    case FetchedTransactions.request(params)
         |> HTTP.json_rpc(indexer_options) do
      {:ok, response} -> {:ok, response}
      {:error, msg} ->
        Logger.error(fn -> ["Failed to request L1 roll up transactions by block range: ", msg] end, block_range: params[:filter])
        {:error, msg}
    end
  end

  def fetch_l1_tx(tx_hash) do
    rpc_options = Application.get_env(:godwoken_explorer, :ckb_rpc_named_arguments)
    case FetchedTransaction.request(tx_hash) |> HTTP.json_rpc(rpc_options) do
      {:ok, response} -> {:ok, response}
      {:error, msg} ->
        Logger.error(fn -> ["Failed to request L1 transaction: ", msg] end, tx_hash: tx_hash)
        {:error, msg}
    end
  end

  def fetch_account_id(account_script_hash) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedAccountID.request(%{script_hash: account_script_hash})
         |> HTTP.json_rpc(options) do
      {:ok, account_id} -> account_id
      {:error, _error} -> nil
    end
  end

  def id_to_params(params_list) do
    params_list
    |> Stream.with_index()
    |> Enum.into(%{}, fn {params, id} -> {id, params} end)
  end
end
