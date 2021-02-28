defmodule GodwokenIndexer.Block.Worker do
  use GenServer

  alias GodwokenRPC.Block.FetchedTipNumber
  alias GodwokenRPC.{Blocks, HTTP}
  alias GodwokenExplorer.Block, as: BlockRepo
  alias GodwokenExplorer.Transaction, as: TransactionRepo
  alias GodwokenExplorer.Chain.Events.Publisher
  import GodwokenRPC.Util, only: [hex_to_number: 1]

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
      next_number = BlockRepo.get_next_number()

      if next_number < tip_number do
        range = next_number..next_number

        {:ok,
         %Blocks{
           blocks_params: blocks_params,
           transactions_params: transactions_params,
           errors: _
         }} = GodwokenRPC.fetch_blocks_by_range(range)

        blocks_params
        |> Enum.each(fn block_params ->
          {:ok, %BlockRepo{hash: hash}} = BlockRepo.create_block(block_params)
          Publisher.broadcast([{:blocks, hash}], :realtime)
        end)

        transactions_params
        |> Enum.each(fn transaction_params ->
          TransactionRepo.create_transaction(transaction_params)
        end)
      end
    end
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
