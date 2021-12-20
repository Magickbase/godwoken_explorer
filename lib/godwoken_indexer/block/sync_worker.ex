defmodule GodwokenIndexer.Block.SyncWorker do
  use GenServer

  import GodwokenRPC.Util, only: [hex_to_number: 1]
  import Ecto.Query, only: [from: 2]

  require Logger

  alias GodwokenRPC.Block.{FetchedTipBlockHash, ByHash}
  alias GodwokenRPC.{Blocks, HTTP}
  alias GodwokenExplorer.{Block, Transaction, Chain, AccountUDT, Repo, Account}
  alias GodwokenExplorer.Chain.Events.Publisher
  alias GodwokenExplorer.Chain.Cache.Blocks, as: BlocksCache
  alias GodwokenExplorer.Chain.Cache.Transactions

  @default_worker_interval 20

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    next_number = get_next_number()
    schedule_work(next_number)

    {:ok, state}
  end

  @impl true
  def handle_info({:work, next_number}, state) do
    {:ok, block_number} = fetch_and_import(next_number)

    # Reschedule once more
    schedule_work(block_number)

    {:noreply, state}
  end

  defp fetch_and_import(next_number) do
    with {:ok, tip_number} <- fetch_tip_number() do
      if next_number <= tip_number do
        range = next_number..next_number

        {:ok,
         %Blocks{
           blocks_params: blocks_params,
           transactions_params: transactions_params,
           errors: _
         }} = GodwokenRPC.fetch_blocks_by_range(range)

        parent_hash =
          blocks_params
          |> List.first
          |> Map.get(:parent_hash)

         if forked?(parent_hash, next_number - 1) do
            Logger.error("!!!!!!Layer2 forked!!!!!!#{next_number - 1}")
            Block.rollback!(parent_hash)
            throw(:rollback)
         end

        inserted_blocks =
          blocks_params
          |> Enum.map(fn block_params ->
            {:ok, %Block{} = block_struct} = Block.create_block(block_params)
            block_struct
          end)

        update_block_cache(inserted_blocks)

        inserted_transactions =
          transactions_params
          |> Enum.map(fn transaction_params ->
            {:ok, %Transaction{} = tx} = Transaction.create_transaction(transaction_params)

            tx |> Map.merge(%{from: Account.display_id(tx.from_account_id), to: Account.display_id(tx.to_account_id)})
          end)
        update_transactions_cache(inserted_transactions)

        broadcast_block_and_tx(inserted_blocks, inserted_transactions)

        trigger_sudt_account_worker(transactions_params)

        {:ok, next_number + 1}
      end
    end
  end

  defp broadcast_block_and_tx(inserted_blocks, inserted_transactions) do
    home_blocks =
      Enum.map(inserted_blocks, fn block ->
        Map.take(block, [:hash, :number, :inserted_at, :transaction_count])
      end)

    home_transactions =
      Enum.map(inserted_transactions, fn tx ->
        tx
        |> Map.take([:hash, :type, :from, :to])
        |> Map.merge(%{
          timestamp: home_blocks |> List.first() |> Map.get(:inserted_at)
        })
      end)

    data = Chain.home_api_data(home_blocks, home_transactions)
    Publisher.broadcast([{:home, data}], :realtime)

    Enum.each(data[:tx_list], fn tx ->
      result = %{
        page: "1",
        total_count: "1",
        txs: [Map.merge(tx, %{block_number: home_blocks |> List.first() |> Map.get(:number)})]
      }

      Publisher.broadcast([{:account_transactions, result}], :realtime)
    end)
  end

  defp trigger_sudt_account_worker(transactions_params) do
    udt_account_ids = extract_sudt_account_ids(transactions_params)

    if length(udt_account_ids) > 0 do
      udt_account_ids
      |> Enum.each(fn {udt_id, account_ids} ->
        account_ids
        |> Enum.each(fn account_id ->
          AccountUDT.sync_balance!(account_id, udt_id)
        end)
      end)
    end
  end

  defp update_block_cache([]), do: :ok

  defp update_block_cache(blocks) when is_list(blocks) do
    BlocksCache.update(blocks)
  end

  defp update_transactions_cache(transactions) do
    Transactions.update(transactions)
  end

  # 0: meta_contract 1: ckb
  defp extract_sudt_account_ids(transactions_params) do
    transactions_params
    |> Enum.reduce([], fn transaction, acc ->
      if transaction |> Map.has_key?(:udt_id) do
        acc ++ [{transaction[:udt_id], transaction[:account_ids]}]
      else
        acc
      end
    end)
    |> Enum.uniq()
  end

  defp fetch_tip_number do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, tip_block_hash} <- FetchedTipBlockHash.request() |> HTTP.json_rpc(options),
         {:ok, %{"block" => %{"raw" => %{"number" => tip_number}}}} <-
           ByHash.request(%{id: 1, hash: tip_block_hash}) |> HTTP.json_rpc(options) do
      {:ok, tip_number |> hex_to_number()}
    end
  end

  defp get_next_number do
    case Repo.one(from block in Block, order_by: [desc: block.number], limit: 1) do
      %Block{number: number} -> number + 1
      nil -> 0
    end
  end

  defp forked?(parent_hash, parent_block_number) do
    case Repo.get_by(Block, number: parent_block_number) do
      nil -> false
      %Block{hash: database_hash} -> parent_hash != database_hash
    end
  end

  defp schedule_work(next_number) do
    second =
      Application.get_env(:godwoken_explorer, :sync_worker_interval) ||
        @default_worker_interval

    Process.send_after(self(), {:work, next_number}, second * 1000)
  end
end
