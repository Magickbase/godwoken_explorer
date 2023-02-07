defmodule GodwokenIndexer.Block.BindL1L2Worker do
  @moduledoc """
  Fetch layer1 rollup cell and bind layer2 block to layer1 block.
  """
  use GenServer

  import GodwokenExplorer.MoleculeParser, only: [parse_global_state: 1, parse_v0_global_state: 1]
  import GodwokenRPC.Util, only: [hex_to_number: 1, number_to_hex: 1]

  require Logger

  alias GodwkenRPC
  alias GodwokenExplorer.Block

  @buffer_block_number 30
  @default_worker_interval 5

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    init_godwoken_l1_block_number =
      Application.get_env(:godwoken_explorer, :init_godwoken_l1_block_number)

    start_block_number =
      case Block.find_last_bind_l1_block() do
        %Block{layer1_block_number: l1_block_number} -> l1_block_number + 1
        nil -> init_godwoken_l1_block_number
      end

    schedule_l1_work(start_block_number)

    {:ok, state}
  end

  def handle_info({:bind_l1_work, block_number}, state) do
    {:ok, l1_tip_number} = GodwokenRPC.fetch_l1_tip_block_nubmer()

    {:ok, next_start_block_number} =
      fetch_l1_number_and_update(block_number, l1_tip_number - @buffer_block_number)

    schedule_l1_work(next_start_block_number)

    {:noreply, state}
  end

  def fetch_l1_number_and_update(start_block_number, l1_tip_number)
      when start_block_number > l1_tip_number do
    {:ok, start_block_number}
  end

  def fetch_l1_number_and_update(start_block_number, l1_tip_number) do
    block_range = cal_block_range(start_block_number, l1_tip_number)
    rollup_cell_type = Application.get_env(:godwoken_explorer, :rollup_cell_type)

    case GodwokenRPC.fetch_l1_txs_by_range(%{
           script: rollup_cell_type,
           script_type: "type",
           order: "asc",
           limit: "0x3e8",
           filter: %{block_range: block_range}
         }) do
      {:ok, response} ->
        case response["objects"] |> Enum.filter(fn obj -> obj["io_type"] == "output" end) do
          txs when txs == [] ->
            {:ok, block_range |> List.last() |> hex_to_number()}

          txs ->
            updated_l1_numbers = parse_data_and_bind(txs)

            if updated_l1_numbers == [] do
              {:ok, block_range |> List.first() |> hex_to_number()}
            else
              {:ok, (updated_l1_numbers |> List.first()) + 1}
            end
        end

      {:error, _} ->
        {:ok, block_range |> List.first() |> hex_to_number()}
    end
  end

  defp parse_data_and_bind(txs) do
    txs
    |> Enum.map(fn %{"block_number" => block_number, "tx_hash" => tx_hash, "io_index" => io_index} ->
      with {:ok, %{"transaction" => %{"outputs_data" => outputs_data}}} <-
             GodwokenRPC.fetch_l1_tx(tx_hash) do
        l2_block_number = parse_outputs_data(outputs_data, io_index)

        Block.bind_l1_l2_block(
          l2_block_number,
          hex_to_number(block_number),
          tx_hash
        )
      else
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort(&(&1 >= &2))
  end

  defp parse_outputs_data(outputs, io_index) do
    {
      _latest_finalized_block_number,
      _reverted_block_root,
      {l2_block_count, _block_merkle_root},
      {_account_count, _account_merkle_root},
      _status
    } =
      try do
        outputs
        |> Enum.at(hex_to_number(io_index))
        |> String.slice(2..-1)
        |> parse_global_state()
      rescue
        ErlangError ->
          outputs
          |> Enum.at(hex_to_number(io_index))
          |> String.slice(2..-1)
          |> parse_v0_global_state()
      end

    l2_block_count - 1
  end

  defp cal_block_range(start_block_number, l1_tip_number) do
    cond do
      start_block_number == l1_tip_number ->
        [l1_tip_number, l1_tip_number]

      start_block_number + 100 < l1_tip_number ->
        [start_block_number, start_block_number + 100]

      start_block_number + 100 >= l1_tip_number ->
        [start_block_number, l1_tip_number]
    end
    |> Enum.map(&number_to_hex(&1))
  end

  defp schedule_l1_work(start_block_number) do
    second =
      Application.get_env(:godwoken_explorer, :bind_l1_worker_interval) ||
        @default_worker_interval

    Process.send_after(self(), {:bind_l1_work, start_block_number}, second * 1000)
  end
end
