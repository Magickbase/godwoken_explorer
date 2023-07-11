defmodule GodwokenRPC do
  @moduledoc """
  Context GodwokenRPC.
  """
  import GodwokenRPC.Util, only: [hex_to_number: 1]

  require Logger

  alias GodwokenRPC.{Blocks, Block, HTTP, Receipts, Contract}

  alias GodwokenRPC.Web3.{
    FetchedBlockByHash,
    FetchedCodes,
    EthCall,
    FetchedPolyVersion
  }

  alias GodwokenRPC.Transaction.FetchedTransaction, as: FetchedGWTransaction
  alias GodwokenRPC.Transaction.FetchedTransactions, as: FetchedGWTransactions
  alias GodwokenRPC.Transaction.{GetGwTxByEthTx, FetchedPendingTxHashes, FetchedEthHashByGwHashes}

  alias GodwokenRPC.CKBIndexer.{
    FetchedTransactions,
    FetchedTransaction,
    FetchedTip,
    FetchedBlock,
    FetchedBlocks,
    FetchedLiveCell,
    FetchedCells
  }

  alias GodwokenRPC.Account.{
    FetchedAccountID,
    FetchedAccountIDs,
    FetchedScriptHash,
    FetchedScriptHashes,
    FetchedScript,
    FetchedScripts,
    FetchedNonce,
    FetchedBalance,
    FetchedBalances
  }

  alias GodwokenRPC.Block.{FetchedTipBlockHash, ByHash}

  alias GodwokenRPC.Transaction.Receipts, as: GWReceipts
  alias GodwokenExplorer.Chain.Hash

  @typedoc """
  Truncated 20-byte [KECCAK-256](https://en.wikipedia.org/wiki/SHA-3) hash encoded as a hexadecimal number in a
  `String.t`.
  """
  @type address :: String.t()

  @type block_number :: non_neg_integer()
  @type hash :: String.t()

  @typedoc """
  Binary data encoded as a single hexadecimal number in a `String.t`
  """
  @type data :: String.t()

  @typedoc """
  A number encoded as a hexadecimal number in a `String.t`

  ## Example

      "0x1b4"

  """
  @type quantity :: String.t()

  @callback fetch_blocks_by_range(Range.t()) :: {:ok, %Blocks{}} | {:error, atom()}
  @callback fetch_script_hashes(list(map())) ::
              {:ok, %GodwokenRPC.Account.FetchedScriptHashes{}} | {:error, atom()}
  @callback fetch_scripts(list(map())) ::
              {:ok, %GodwokenRPC.Account.FetchedScripts{}} | {:error, atom()}
  @callback fetch_balances(
              list(%{
                :registry_address => String.t(),
                :udt_id => integer(),
                :account_id => integer() | nil,
                :udt_script_hash => String.t() | Hash.t(),
                :eth_address => Hash.t() | nil,
                optional(:layer1_block_number) => integer(),
                optional(:script_hash) => Hash.t()
              })
            ) :: {:ok, %GodwokenRPC.Account.FetchedBalances{}} | {:error, atom()}

  @callback fetch_eth_hash_by_gw_hashes(list(map())) ::
              {:ok, %GodwokenRPC.Transaction.FetchedEthHashByGwHashes{}} | {:error, atom()}

  @callback fetch_transaction_receipts(list(map())) :: nil | {:ok, map()}
  @callback fetch_gw_transaction_receipts(list(map())) :: {:ok, map()}
  @callback fetch_account_id(String.t()) ::
              {:error, :account_slow | :network_error} | {:ok, integer}
  @callback fetch_account_ids(list(map())) :: nil | {:ok, map()}
  @callback fetch_nonce(integer) :: nil | integer
  @callback fetch_script(String.t()) :: {:error, :network_error} | {:ok, map()}
  @callback fetch_script_hash(%{:account_id => integer}) ::
              {:error, :network_error} | {:ok, String.t()}
  @callback fetch_tip_block_number() :: {:error, any()} | {:ok, integer()}
  @callback fetch_l1_tip_block_number() :: {:error, any()} | {:ok, integer()}
  @callback fetch_l1_blocks(list(%{block_number: non_neg_integer()})) ::
              {:ok, %GodwokenRPC.CKBIndexer.FetchedBlocks{}} | {:error, any()}

  def request(%{method: method, params: params} = map)
      when is_binary(method) and is_list(params) do
    Map.put(map, :jsonrpc, "2.0")
  end

  def request(%{method: method} = map)
      when is_binary(method) do
    Map.put(map, :jsonrpc, "2.0")
  end

  @spec fetch_blocks_by_range(Range.t()) :: {:ok, %Blocks{}}
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

  @spec fetch_tip_block_number :: {:error, String.t()} | {:ok, integer()}
  def fetch_tip_block_number do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, tip_block_hash} <- FetchedTipBlockHash.request() |> HTTP.json_rpc(options),
         {:ok, %{"block" => %{"raw" => %{"number" => tip_number}}}} <-
           ByHash.request(%{id: 1, hash: tip_block_hash}) |> HTTP.json_rpc(options) do
      {:ok, tip_number |> hex_to_number()}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def fetch_nonce_by_ids(ids) do
    ids
    |> fetch_nonce_by_params(&GodwokenRPC.Account.FetchedNonce.request/1)
  end

  defp fetch_nonce_by_params(params, request)
       when is_list(params) and is_function(request, 1) do
    id_to_params =
      params
      |> Enum.into(%{}, fn params -> {params[:account_id], params} end)

    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> Blocks.requests(request)
           |> HTTP.json_rpc(options) do
      {:ok,
       responses
       |> Enum.map(fn response ->
         %{id: response[:id], nonce: hex_to_number(response[:result])}
       end)}
    end
  end

  def fetch_l1_tip_block_number do
    indexer_options = Application.get_env(:godwoken_explorer, :ckb_rpc_named_arguments)

    case FetchedTip.request() |> HTTP.json_rpc(indexer_options) do
      {:ok, %{"block_number" => l1_tip_block_number}} ->
        {:ok, hex_to_number(l1_tip_block_number)}

      {:error, msg} ->
        Logger.error(fn -> ["Failed to request L1 tip block number: ", msg] end)
        {:error, msg}
    end
  end

  def fetch_l1_txs_by_range(params) do
    indexer_options = Application.get_env(:godwoken_explorer, :ckb_rpc_named_arguments)

    case FetchedTransactions.request(params)
         |> HTTP.json_rpc(indexer_options) do
      {:ok, response} ->
        {:ok, response}

      {:error, msg} ->
        Logger.error(
          fn -> ["Failed to request L1 roll up transactions by block range: ", msg] end,
          block_range: params[:filter]
        )

        {:error, msg}
    end
  end

  def fetch_l1_tx(tx_hash) do
    rpc_options = Application.get_env(:godwoken_explorer, :ckb_rpc_named_arguments)

    case FetchedTransaction.request(tx_hash) |> HTTP.json_rpc(rpc_options) do
      {:ok, response} ->
        {:ok, response}

      {:error, msg} ->
        Logger.error(fn -> ["Failed to request L1 transaction: ", msg] end, tx_hash: tx_hash)
        {:error, msg}
    end
  end

  def fetch_l1_block(block_number) do
    rpc_options = Application.get_env(:godwoken_explorer, :ckb_rpc_named_arguments)

    case FetchedBlock.request(%{id: 1, block_number: block_number})
         |> HTTP.json_rpc(rpc_options) do
      {:ok, response} ->
        {:ok, response}

      {:error, msg} ->
        Logger.error(fn -> ["Failed to request L1 block: ", msg] end,
          block_number: block_number
        )

        {:error, msg}
    end
  end

  def fetch_l1_blocks(params) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :ckb_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> FetchedBlocks.requests()
           |> HTTP.json_rpc(options) do
      {:ok, FetchedBlocks.from_responses(responses, id_to_params)}
    end
  end

  def fetch_account_ids(params) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> FetchedAccountIDs.requests()
           |> HTTP.json_rpc(options) do
      {:ok, FetchedAccountIDs.from_responses(responses, id_to_params)}
    end
  end

  @spec fetch_account_id(String.t()) :: {:error, :account_slow | :network_error} | {:ok, integer}
  def fetch_account_id(account_script_hash) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedAccountID.request(%{id: 1, script: nil, script_hash: account_script_hash})
         |> HTTP.json_rpc(options) do
      {:ok, account_id} when is_nil(account_id) ->
        Logger.error("Fetch account succeed.But is nil!!!:#{account_script_hash}")
        {:error, :account_slow}

      {:ok, account_id} ->
        {:ok, account_id |> hex_to_number()}

      {:error, msg} ->
        Logger.error("Failed to fetch #{account_script_hash} L2 account_id: #{inspect(msg)}")

        {:error, :network_error}
    end
  end

  @spec fetch_script_hash(%{:account_id => integer}) ::
          {:error, :network_error} | {:ok, String.t()}
  def fetch_script_hash(%{account_id: account_id}) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedScriptHash.request(%{id: 0, account_id: account_id})
         |> HTTP.json_rpc(options) do
      {:ok, script_hash} ->
        {:ok, script_hash}

      {:error, msg} ->
        Logger.error("Failed to fetch #{account_id} script_hash: #{inspect(msg)}")

        {:error, :network_error}
    end
  end

  @spec fetch_script_hashes(list(map())) :: {:ok, %GodwokenRPC.Account.FetchedScriptHashes{}}
  def fetch_script_hashes(params) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> FetchedScriptHashes.requests()
           |> HTTP.json_rpc(options) do
      {:ok, FetchedScriptHashes.from_responses(responses, id_to_params)}
    end
  end

  @spec fetch_script(String.t()) :: {:error, :network_error} | {:ok, map()}
  def fetch_script(script_hash) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedScript.request(%{id: 0, script_hash: script_hash})
         |> HTTP.json_rpc(options) do
      {:ok, script} ->
        {:ok, script}

      {:error, msg} ->
        Logger.error("Failed to fetch script #{script_hash} : #{inspect(msg)}")
        {:error, :network_error}
    end
  end

  @spec fetch_scripts(list(map())) :: {:ok, %GodwokenRPC.Account.FetchedScripts{}}
  def fetch_scripts(params) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> FetchedScripts.requests()
           |> HTTP.json_rpc(options) do
      {:ok, FetchedScripts.from_responses(responses, id_to_params)}
    end
  end

  @spec fetch_nonce(integer) :: nil | integer
  def fetch_nonce(account_id) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedNonce.request(%{account_id: account_id})
         |> HTTP.json_rpc(options) do
      {:ok, nonce} -> nonce |> hex_to_number()
      {:error, _error} -> nil
    end
  end

  def execute_contract_functions(
        functions,
        abi,
        json_rpc_named_arguments,
        leave_error_as_map \\ false
      ) do
    if Enum.count(functions) > 0 do
      Contract.execute_contract_functions(
        functions,
        abi,
        json_rpc_named_arguments,
        leave_error_as_map
      )
    else
      []
    end
  end

  @spec fetch_balances(
          list(%{
            :registry_address => String.t(),
            :udt_id => integer(),
            :account_id => integer() | nil,
            :udt_script_hash => String.t() | Hash.t(),
            :eth_address => Hash.t() | nil,
            optional(:layer1_block_number) => integer(),
            optional(:script_hash) => Hash.t()
          })
        ) :: {:ok, %GodwokenRPC.Account.FetchedBalances{}}
  def fetch_balances(params) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> FetchedBalances.requests()
           |> HTTP.json_rpc(options) do
      {:ok, FetchedBalances.from_responses(responses, id_to_params)}
    end
  end

  @spec fetch_balance(any, integer) :: {:error, 0} | {:ok, integer}
  def fetch_balance(registry_address, udt_id) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedBalance.request(%{id: 0, registry_address: registry_address, udt_id: udt_id})
         |> HTTP.json_rpc(options) do
      {:ok, balance} -> {:ok, balance |> hex_to_number()}
      {:error, _error} -> {:error, 0}
    end
  end

  @spec fetch_transaction_receipts(list(map())) :: nil | {:ok, map()}
  def fetch_transaction_receipts(transactions_params) when is_list(transactions_params) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    Receipts.fetch(transactions_params, options)
  end

  @spec fetch_gw_transaction_receipts(list(map())) :: {:ok, map()}
  def fetch_gw_transaction_receipts(transactions_params) when is_list(transactions_params) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    GWReceipts.fetch(transactions_params, options)
  end

  def fetch_codes(params) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> FetchedCodes.requests()
           |> HTTP.json_rpc(options) do
      {:ok, FetchedCodes.from_responses(responses, id_to_params)}
    end
  end

  def fetch_eth_block_by_hash(block_hash) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedBlockByHash.request(block_hash) |> HTTP.json_rpc(options) do
      {:ok, response} ->
        {:ok, response}

      _ ->
        Logger.error("Failed to fetch eth block receipt: #{block_hash}")
        {:error, :network_error}
    end
  end

  def fetch_cells(script, script_type) do
    options = Application.get_env(:godwoken_explorer, :ckb_rpc_named_arguments)

    case FetchedCells.request(script, script_type) |> HTTP.json_rpc(options) do
      {:ok, response} ->
        {:ok, response}

      _ ->
        Logger.error("Failed to fetch cells: #{inspect(script)}")
        {:error, 0}
    end
  end

  def fetch_live_cell(index, tx_hash) do
    rpc_options = Application.get_env(:godwoken_explorer, :ckb_rpc_named_arguments)

    case FetchedLiveCell.request(index, tx_hash) |> HTTP.json_rpc(rpc_options) do
      {:ok, response} ->
        {:ok, response["status"] == "live"}

      {:error, msg} ->
        Logger.error("Failed to request live cell: #{tx_hash}:#{index} for #{inspect(msg)}")
        {:error, :node_error}
    end
  end

  @spec fetch_mempool_transaction(String.t()) ::
          {:error, :node_error}
          | {:ok,
             %{
               status: String.t(),
               transaction: %{
                 hash: String.t(),
                 raw: %{
                   args: String.t(),
                   chain_id: String.t(),
                   from_id: String.t(),
                   nonce: String.t(),
                   to_id: String.t()
                 },
                 signature: String.t()
               }
             }}
  def fetch_mempool_transaction(tx_hash) do
    options = Application.get_env(:godwoken_explorer, :mempool_rpc_named_arguments)

    with {:ok, gw_tx_hash} <-
           GetGwTxByEthTx.request(tx_hash) |> HTTP.json_rpc(options),
         {:ok, response} <-
           FetchedGWTransaction.request(%{id: 1, gw_tx_hash: gw_tx_hash})
           |> HTTP.json_rpc(options) do
      {:ok, response}
    else
      {:error, msg} ->
        Logger.error("Failed to request transaction: #{tx_hash} > #{inspect(msg)}")
        {:error, :node_error}
    end
  end

  def fetch_pending_tx_hashes() do
    options = Application.get_env(:godwoken_explorer, :mempool_rpc_named_arguments)

    with {:ok, response} <- FetchedPendingTxHashes.request() |> HTTP.json_rpc(options) do
      {:ok, response}
    else
      {:error, msg} ->
        Logger.error("Failed to fetched pending tx hashes: #{inspect(msg)}")
        {:error, :node_error}
    end
  end

  def fetch_pending_transactions(params) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :mempool_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> FetchedGWTransactions.requests()
           |> HTTP.json_rpc(options) do
      {:ok, FetchedGWTransactions.from_responses(responses, id_to_params)}
    end
  end

  def eth_call(params) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case EthCall.request(params)
         |> HTTP.json_rpc(options) do
      {:ok, response} ->
        {:ok, response}

      {:error, msg} ->
        Logger.error("Failed to eth call: #{inspect(msg)} #{inspect(params)}")
        {:error, :node_error}
    end
  end

  def fetch_poly_version() do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedPolyVersion.request() |> HTTP.json_rpc(options) do
      {:ok, response} ->
        {:ok, response}

      _ ->
        Logger.error("Failed to fetch poly version")
        {:error, nil}
    end
  end

  @spec fetch_eth_hash_by_gw_hashes(list(map())) ::
          {:ok, %GodwokenRPC.Transaction.FetchedEthHashByGwHashes{}}
  def fetch_eth_hash_by_gw_hashes(params) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> FetchedEthHashByGwHashes.requests()
           |> HTTP.json_rpc(options) do
      {:ok, FetchedEthHashByGwHashes.from_responses(responses, id_to_params)}
    end
  end

  def id_to_params(params_list) do
    params_list
    |> Stream.with_index()
    |> Enum.into(%{}, fn {params, id} -> {id, params} end)
  end

  def integer_to_quantity(integer) when is_integer(integer) and integer >= 0 do
    "0x" <> Integer.to_string(integer, 16)
  end

  def quantity_to_integer("0x" <> hexadecimal_digits) do
    String.to_integer(hexadecimal_digits, 16)
  end

  def quantity_to_integer(integer) when is_integer(integer), do: integer

  def quantity_to_integer(string) when is_binary(string) do
    case Integer.parse(string) do
      {integer, ""} -> integer
      _ -> :error
    end
  end
end
