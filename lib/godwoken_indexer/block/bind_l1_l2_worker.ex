defmodule GodwokenIndexer.Block.BindL1L2Worker do
  use GenServer

  import Godwoken.MoleculeParser, only: [parse_global_state: 1]
  import GodwokenRPC.Util, only: [hex_to_number: 1, number_to_hex: 1]

  alias GodwokenRPC.CKBIndexer.{FetchedTransactions, FetchedTransaction, FetchedTip}
  alias GodwokenExplorer.Block
  alias GodwokenRPC.HTTP

  @init_godwoken_l1_block_number 1798

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    # Schedule work to be performed on start

    start_block_number = case Block.find_last_bind_l1_block() do
      %Block{layer1_block_number: l1_block_number} -> l1_block_number + 1
      nil -> @init_godwoken_l1_block_number
    end
    schedule_work(start_block_number)

    {:ok, state}
  end

  @impl true
  def handle_info({:bind_work, block_number}, state) do
    # Do the desired work here
    {:ok, start_block_number} = fetch_and_update(block_number)

    # Reschedule once more
    schedule_work(start_block_number)

    {:noreply, state}
  end

  defp fetch_and_update(start_block_number) do
    {:ok, %{"block_number" => l1_block_number}} = fetch_tip_block_nubmer()
    block_range =
      if hex_to_number(l1_block_number) <= start_block_number + 100 do
        [number_to_hex(start_block_number), l1_block_number]
      else
        [number_to_hex(start_block_number), number_to_hex(start_block_number + 100)]
      end

    indexer_options = Application.get_env(:godwoken_explorer, :ckb_indexer_named_arguments)
    rpc_options = Application.get_env(:godwoken_explorer, :ckb_rpc_named_arguments)
    state_validator_lock = Application.get_env(:godwoken_explorer, :state_validator_lock)

    with {:ok, response} <- FetchedTransactions.request(state_validator_lock, "lock", "asc", "0x3e8", %{block_range: block_range}) |> HTTP.json_rpc(indexer_options) do
      response["objects"]
      |> Enum.filter(fn obj -> obj["io_type"] == "output" end)
      |> Enum.each(fn %{"block_number" => block_number, "tx_hash" => tx_hash, "io_index" => io_index } ->
        with {:ok, %{"transaction" => %{"outputs_data" => outputs_data}} } <- FetchedTransaction.request(tx_hash) |> HTTP.json_rpc(rpc_options) do
          {
            :ok,
            _latest_finalized_block_number,
            l2_block_count,
            _account_count,
            _reverted_block_root,
            _block_merkle_root,
            _account_merkle_root
          } = outputs_data
              |> Enum.at(hex_to_number(io_index))
              |> String.slice(2..-1)
              |> parse_global_state()
          Block.bind_l1_l2_block(l2_block_count - 1, hex_to_number(block_number), tx_hash)
        end
      end)

      {:ok, block_range |> List.last() |> hex_to_number()}
    end
  end

  defp fetch_tip_block_nubmer do
    indexer_options = Application.get_env(:godwoken_explorer, :ckb_indexer_named_arguments)
    FetchedTip.request() |> HTTP.json_rpc(indexer_options)
  end

  defp schedule_work(start_block_number) do
    Process.send_after(self(), {:bind_work, start_block_number}, 10 * 1000)
  end
end
