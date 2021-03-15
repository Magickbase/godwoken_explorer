defmodule GodwokenIndexer.Block.SyncWorker do
  use GenServer

  import GodwokenRPC.Util, only: [hex_to_number: 1]

  alias GodwokenRPC.Block.FetchedTipNumber
  alias GodwokenRPC.{Blocks, HTTP}
  alias GodwokenExplorer.{Block, Transaction, Chain}
  alias GodwokenExplorer.Chain.Events.Publisher
  alias GodwokenIndexer.Account.Worker, as: AccountWorker
  alias GodwokenExplorer.Chain.Cache.Blocks, as: BlocksCache
  alias GodwokenExplorer.Chain.Cache.Transactions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    # Schedule work to be performed on start
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    # Do the desired work here
    fetch_and_import()

    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  defp fetch_and_import do
    with {:ok, tip_number} <- fetch_tip_number() do
      next_number = Block.get_next_number()

      if next_number <= tip_number do
        range = next_number..next_number

        {:ok,
          %Blocks{
            blocks_params: blocks_params,
            transactions_params: transactions_params,
            errors: _
          }
        } = GodwokenRPC.fetch_blocks_by_range(range)

        inserted_blocks =
          blocks_params |> Enum.map(fn block_params ->
            {:ok, %Block{} = block_struct} = Block.create_block(block_params)
            block_struct
          end)

        update_block_cache(inserted_blocks)

        inserted_transactions =
          transactions_params |> Enum.map(fn transaction_params ->
            {:ok, %Transaction{} = transaction_struct} = Transaction.create_transaction(transaction_params)
            transaction_struct
          end)

        update_transactions_cache(inserted_transactions)

        home_blocks = Enum.map(inserted_blocks, fn block -> Map.take(block, [:hash, :number, :timestamp, :transaction_count]) end)
        home_transactions =
          Enum.map(inserted_transactions, fn tx ->
            tx
            |> Map.take([:hash, :from_account_id, :to_account_id, :type])
            |> Map.merge(%{timestamp: home_blocks |> List.first() |> Map.get(:timestamp), success: true})
          end)
        data = Chain.home_api_data(home_blocks, home_transactions)

        Publisher.broadcast([{:home, data}], :realtime)

        account_ids = extract_account_ids(transactions_params)
        sudt_account_ids = extract_sudt_account_ids(transactions_params)

        if length(account_ids) > 0 do
          AccountWorker.trigger_account(account_ids)
        end

        if length(sudt_account_ids) > 0 do
          AccountWorker.trigger_sudt_account(sudt_account_ids)
        end
      end
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
  defp extract_account_ids(transactions_params) do
    transactions_params |> Enum.reduce([], fn transaction, acc ->
      acc ++ transaction[:account_ids]
    end)
    |> Enum.uniq()
    |> Enum.reject(& (&1 in [0, 1]))
  end
  defp extract_sudt_account_ids(transactions_params) do
    transactions_params |> Enum.reduce([], fn transaction, acc ->
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

    with {:ok, tip_number} <-
           FetchedTipNumber.request()
           |> HTTP.json_rpc(options) do

      {:ok, tip_number |> hex_to_number()}
    end
  end

  defp schedule_work do
    Process.send_after(self(), :work, 2 * 1000)
  end
end
