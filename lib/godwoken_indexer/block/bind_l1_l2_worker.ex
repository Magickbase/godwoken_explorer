defmodule GodwokenIndexer.Block.BindL1L2Worker do
  use GenServer

  import Godwoken.MoleculeParser, only: [parse_global_state: 1, parse_deposition_lock_args: 1]
  import GodwokenRPC.Util, only: [hex_to_number: 1, number_to_hex: 1]

  alias GodwkenRPC
  alias GodwokenExplorer.{Block, Account}

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    init_godwoken_l1_block_number = Application.get_env(:godwoken_explorer, :init_godwoken_l1_block_number)
    start_block_number =
      case Block.find_last_bind_l1_block() do
        %Block{layer1_block_number: l1_block_number} -> l1_block_number + 1
        nil -> init_godwoken_l1_block_number
      end

    schedule_work(start_block_number)

    {:ok, state}
  end

  @impl true
  def handle_info({:bind_work, block_number}, state) do
    {:ok, l1_tip_number} = GodwokenRPC.fetch_l1_tip_block_nubmer()
    {:ok, next_start_block_number} = fetch_l1_number_and_update(block_number, l1_tip_number)
    fetch_ckb_lock_script_and_update(block_number, l1_tip_number)

    schedule_work(next_start_block_number)

    {:noreply, state}
  end

  defp fetch_l1_number_and_update(start_block_number, l1_tip_number) when start_block_number > l1_tip_number do
    {:ok, start_block_number}
  end
  defp fetch_l1_number_and_update(start_block_number, l1_tip_number) do
    block_range = cal_block_range(start_block_number, l1_tip_number)
    state_validator_lock = Application.get_env(:godwoken_explorer, :state_validator_lock)

    case GodwokenRPC.fetch_l1_txs_by_range(%{
                                                    script: state_validator_lock,
                                                    script_type: "lock",
                                                    order: "asc",
                                                    limit: "0x64",
                                                    filter: %{block_range: block_range}
                                                  }) do
      {:ok, response} ->
         case response["objects"] |> Enum.filter(fn obj -> obj["io_type"] == "output" end) do
           txs when txs == [] -> {:ok, block_range |> List.last() |> hex_to_number()}
           txs ->
            updated_l1_numbers = parse_data_and_bind(txs)
            if length(updated_l1_numbers) == 0 do
              {:ok, block_range |> List.first() |> hex_to_number()}
            else
              {:ok, (updated_l1_numbers|> List.first()) + 1}
            end
         end
      {:error, _} -> {:ok, block_range |> List.first() |> hex_to_number() }
    end
  end

  defp fetch_ckb_lock_script_and_update(start_block_number, l1_tip_number) do
    block_range = cal_block_range(start_block_number, l1_tip_number)
    deposition_lock = Application.get_env(:godwoken_explorer, :deposition_lock)

    with {:ok, response} <- GodwokenRPC.fetch_l1_txs_by_range(%{
                                                    script: deposition_lock,
                                                    script_type: "lock",
                                                    order: "asc",
                                                    limit: "0x64",
                                                    filter: %{block_range: block_range}
                                                  }) ,
         txs when txs != [] <- response["objects"] |> Enum.filter(fn obj -> obj["io_type"] == "output" end) do
         parse_lock_script_and_bind(txs)
    end
  end

  defp parse_lock_script_and_bind(txs) do
    txs
    |> Enum.map(fn %{"tx_hash" => tx_hash, "io_index" => io_index} ->
      with {:ok, %{"transaction" => %{"inputs" => inputs, "outputs" => outputs}}} <- GodwokenRPC.fetch_l1_tx(tx_hash) do
        {:ok, l2_script_hash, l1_lock_hash} = parse_lock_args(outputs, io_index)
        ckb_lock_script = get_ckb_lock_script(inputs, outputs, io_index)

        Account.bind_ckb_lock_script(ckb_lock_script, "0x" <> l2_script_hash, "0x" <> l1_lock_hash)
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort(&(&1 >= &2))
  end
  defp parse_lock_args(outputs, io_index) do
    outputs
    |> Enum.at(hex_to_number(io_index))
    |> Map.get("lock")
    |> Map.get("args")
    |> String.slice(2..-1)
    |> parse_deposition_lock_args()
  end
  defp get_ckb_lock_script(inputs, outputs, io_index) do
    if length(outputs) > 1 do
      outputs
      |> List.delete_at(hex_to_number(io_index))
      |> List.first()
      |> Map.get("lock")
    else
      %{"previous_output" => %{"index" => index, "tx_hash" => tx_hash}} = inputs |> List.first()
      with {:ok, %{"transaction" => %{"outputs" => outputs}}} <- GodwokenRPC.fetch_l1_tx(tx_hash) do
        outputs
        |> Enum.at(hex_to_number(index))
        |> Map.get("lock")
      end
    end
    |> Map.merge(%{"name" => "secp256k1/blake160"})
  end

  defp parse_data_and_bind(txs) do
    txs
    |> Enum.map(fn %{"block_number" => block_number, "tx_hash" => tx_hash, "io_index" => io_index} ->
      with {:ok, %{"transaction" => %{"outputs_data" => outputs_data}}} <- GodwokenRPC.fetch_l1_tx(tx_hash) do
        l2_block_number = parse_outputs_data(outputs_data, io_index)

        Block.bind_l1_l2_block(l2_block_number, hex_to_number(block_number), tx_hash)
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort(&(&1 >= &2))
  end

  defp parse_outputs_data(outputs, io_index) do
    {
      :ok,
      _latest_finalized_block_number,
      _reverted_block_root,
      {l2_block_count, _block_merkle_root},
      {_account_count, _account_merkle_root},
      _status
    } =
      outputs
      |> Enum.at(hex_to_number(io_index))
      |> String.slice(2..-1)
      |> parse_global_state()

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
    |> Enum.map(& number_to_hex(&1))
  end

  defp schedule_work(start_block_number) do
    Process.send_after(self(), {:bind_work, start_block_number}, 10 * 1000)
  end
end
