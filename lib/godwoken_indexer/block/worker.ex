defmodule GodwokenIndexer.Block.Worker do
  use GenServer

  alias GodwokenRPC.{TipNumber, Blocks}
  alias GodwokenExplorer.Block, as: BlockRepo
  alias GodwokenExplorer.Transaction, as: TransactionRepo
  alias GodwokenExplorer.Chain.Events.Publisher
  alias GodwokenExplorer.Repo

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
    with {:ok, max_number} <- fetch_max_number() do
      next_number = BlockRepo.get_next_number()

      if next_number < max_number do
        range = next_number..next_number

        {:ok,
         %Blocks{
           blocks_params: blocks_params,
           transactions_params: transactions_params,
           errors: _
         }} = GodwokenRPC.fetch_blocks_by_range(range)

        Repo.transaction(fn ->
          blocks_params
          |> Enum.each(fn block_params ->
            %BlockRepo{hash: hash} = BlockRepo.create_block(block_params)
            Publisher.broadcast([{:blocks, hash}], :realtime)
          end)

          transactions_params
          |> Enum.each(fn transaction_params ->
            TransactionRepo.create_transaction(transaction_params)
          end)
        end)
      end
    end
  end

  defp fetch_max_number do
    case TipNumber.request() do
      {:ok, %{body: body, status_code: 200}} ->
        max_number =
          body
          |> Jason.decode!()
          |> Map.fetch!("result")
          |> String.slice(2..-1)
          |> String.to_integer(16)

        {:ok, max_number}

      _ ->
        {:error, -1}
    end
  end

  defp schedule_work do
    Process.send_after(self(), :work, 2 * 1000)
  end
end
