defmodule GodwokenIndexer.Block.FinalizedWorker do
  use GenServer

  import Godwoken.MoleculeParser, only: [parse_global_state: 1]

  alias GodwokenRPC.CKBIndexer.FetchedGlobalState
  alias GodwokenExplorer.Block, as: BlockRepo
  alias GodwokenRPC.HTTP

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
  def handle_info(:finalized_work, state) do
    # Do the desired work here
    fetch_and_update()

    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  defp fetch_and_update do
    with {:ok, block_number} <- fetch_latest_finalized_block_number() do
      BlockRepo.update_blocks_finalized(block_number)
    end
  end

  defp fetch_latest_finalized_block_number do
    options = Application.get_env(:godwoken_explorer, :ckb_indexer_named_arguments)

    with {:ok, response} <- FetchedGlobalState.request() |> HTTP.json_rpc(options),
         "0x" <> global_state <- response["objects"] |> List.first() |> Map.fetch!("output_data"),
         {:ok, latest_finalized_block_number } <- global_state |> parse_global_state() do
      {:ok, latest_finalized_block_number}
    end
  end

  defp schedule_work do
    Process.send_after(self(), :finalized_work, 5 * 1000)
  end
end
