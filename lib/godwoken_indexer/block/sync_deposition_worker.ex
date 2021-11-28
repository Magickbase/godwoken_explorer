defmodule GodwokenIndexer.Block.SyncDepositionWorker do
  use GenServer

  import Godwoken.MoleculeParser, only: [parse_deposition_lock_args: 1]
  import GodwokenRPC.Util, only: [hex_to_number: 1, number_to_hex: 1, script_to_hash: 1]

  require Logger

  alias GodwkenRPC
  alias GodwokenExplorer.{Block, Account}
  alias GodwokenIndexer.Account.Worker

  @buffer_block_number 10
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

    schedule_work(start_block_number)

    {:ok, state}
  end

  def handle_info({:bind_deposit_work, block_number}, state) do
    {:ok, l1_tip_number} = GodwokenRPC.fetch_l1_tip_block_nubmer()

    {:ok, next_start_block_number} =
      fetch_deposition_script_and_update(
        block_number,
        l1_tip_number
      )

    schedule_work(next_start_block_number)

    {:noreply, state}
  end

  def fetch_deposition_script_and_update(start_block_number, l1_tip_number) do
    Logger.info("#{start_block_number}-----#{l1_tip_number}")
    block_range = cal_block_range(start_block_number, l1_tip_number - @buffer_block_number)
    deposition_lock = Application.get_env(:godwoken_explorer, :deposition_lock)

    case(
      GodwokenRPC.fetch_l1_txs_by_range(%{
        script: deposition_lock,
        script_type: "lock",
        order: "asc",
        limit: "0x3e8",
        filter: %{block_range: block_range}
      })
    ) do
      {:ok, response} ->
        txs = response["objects"] |> Enum.filter(fn obj -> obj["io_type"] == "output" end)

        if txs != [] do
          try do
            Logger.info("size: #{Enum.count(txs)}")
            parse_lock_script_and_bind(txs)
          rescue
            _ ->
              Logger.error("==============fetch_deposition_script_and_update")
              fetch_deposition_script_and_update(start_block_number, l1_tip_number)
          end
        end

        {:ok, block_range |> List.last() |> hex_to_number()}

      _ ->
        {:ok, block_range |> List.first() |> hex_to_number()}
    end
  end

  defp parse_lock_script_and_bind(txs) do
    Enum.each(txs, fn %{"tx_hash" => tx_hash, "io_index" => io_index} ->
      with {:ok, %{"transaction" => %{"inputs" => inputs, "outputs" => outputs}}} <-
             GodwokenRPC.fetch_l1_tx(tx_hash) do
        {l2_script_hash, l1_lock_hash} = parse_lock_args(outputs, io_index)
        ckb_lock_script = get_ckb_lock_script(inputs, outputs, io_index)

        user_account =
          Account.bind_ckb_lock_script(
            ckb_lock_script,
            "0x" <> l2_script_hash,
            "0x" <> l1_lock_hash
          )

        Logger.info((user_account |> elem(1)).id)
        Logger.info("l2:#{l2_script_hash}")
        {udt_script, udt_script_hash} = parse_udt_script(outputs, io_index)
        Logger.info("udt:#{udt_script_hash}")

        with {:ok, user} <- user_account do
          Worker.trigger_account([user.id])
        end

        with {:ok, udt_account_id} <- Account.create_udt_account(udt_script, udt_script_hash) do
          case user_account do
            {:ok, user} ->
              Worker.trigger_sudt_account([{udt_account_id, [user.id]}])

            {:error, nil} ->
              Worker.trigger_account([udt_account_id])
          end
        end
      else
        _ ->
          Logger.error("==============")
          Logger.error("#{tx_hash} get failed")
      end
    end)
  end

  defp parse_udt_script(outputs, io_index) do
    case outputs
         |> Enum.at(hex_to_number(io_index))
         |> Map.get("type") do
      nil ->
        {nil, "0x0000000000000000000000000000000000000000000000000000000000000000"}

      %{} = udt_script ->
        {udt_script, script_to_hash(udt_script)}
    end
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

  def cal_block_range(start_block_number, l1_tip_number) do
    cond do
      start_block_number == l1_tip_number ->
        [l1_tip_number, l1_tip_number + 1]

      start_block_number + 1 < l1_tip_number ->
        [start_block_number, start_block_number + 1]

      start_block_number + 1 >= l1_tip_number ->
        [start_block_number, l1_tip_number]
    end
    |> Enum.map(&number_to_hex(&1))
  end

  defp schedule_work(start_block_number) do
    second =
      Application.get_env(:godwoken_explorer, :sync_deposition_worker_interval) ||
        @default_worker_interval

    Process.send_after(self(), {:bind_deposit_work, start_block_number}, second * 1000)
  end
end
