defmodule GodwokenIndexer.Block.TempSyncDepositionWorker do
  use GenServer

  import Godwoken.MoleculeParser, only: [parse_deposition_lock_args: 1]
  import GodwokenRPC.Util, only: [hex_to_number: 1, number_to_hex: 1, script_to_hash: 1]

  require Logger

  alias GodwkenRPC
  alias GodwokenExplorer.{Account}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: TempWorker)
  end

  def init(state) do
    {:ok, state}
  end

  def trigger_deposit(block_range) do
    GenServer.cast(TempWorker, {:bind_deposit_worker, block_range})
  end

  def handle_cast({:bind_deposit_worker, block_range}, state) do
    fetch_deposition_script_and_update(block_range)

    {:noreply, state}
  end

  def fetch_deposition_script_and_update(original_block_range) do
    block_range = original_block_range |> Enum.map(&number_to_hex(&1))
    deposition_lock = Application.get_env(:godwoken_explorer, :deposition_lock)

    with {:ok, response} <-
           GodwokenRPC.fetch_l1_txs_by_range(%{
             script: deposition_lock,
             script_type: "lock",
             order: "asc",
             limit: "0x3e8",
             filter: %{block_range: block_range}
           }),
         txs when txs != [] <-
           response["objects"] |> Enum.filter(fn obj -> obj["io_type"] == "output" end) do
      try do
        Logger.info("#{original_block_range |> List.first()}")
        parse_lock_script_and_bind(txs)
      catch
        e ->
          Logger.error(e)
          fetch_deposition_script_and_update(original_block_range)
      end

      {:ok, block_range |> List.last() |> hex_to_number()}
    else
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

        {udt_script, udt_script_hash} = parse_udt_script(outputs, io_index)

        with {:ok, udt_account_id} <- Account.create_udt_account(udt_script, udt_script_hash) do
          case user_account do
            {:ok, user} ->
              case GodwokenIndexer.Account.SyncDepositSupervisor.start_child([user.id]) do
                {:ok, from_pid} ->
                  GodwokenIndexer.Account.SyncDepositWorker.trigger_account(from_pid)

                {:error, {:already_started, _from_pid}} ->
                  Logger.error("alreay started#{user.id}")
              end

              case GodwokenIndexer.Account.SyncDepositSupervisor.start_child([
                     {udt_account_id, [user.id]}
                   ]) do
                {:ok, from_pid} ->
                  GodwokenIndexer.Account.SyncDepositWorker.trigger_sudt_account(from_pid)

                {:error, {:already_started, _from_pid}} ->
                  Logger.error("alreay started#{user.id}")
              end

            {:error, nil} ->
              case GodwokenIndexer.Account.SyncDepositSupervisor.start_child([udt_account_id]) do
                {:ok, from_pid} ->
                  GodwokenIndexer.Account.SyncDepositWorker.trigger_account(from_pid)

                {:error, {:already_started, _from_pid}} ->
                  Logger.error("alreay started#{udt_account_id}")
              end
          end
        end
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
end
