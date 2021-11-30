defmodule GodwokenIndexer.Block.SyncL1BlockWorker do
  use GenServer

  import Godwoken.MoleculeParser, only: [parse_deposition_lock_args: 1]
  import GodwokenRPC.Util, only: [hex_to_number: 1, script_to_hash: 1]

  require Logger

  alias GodwkenRPC
  alias GodwokenExplorer.{Account, CheckInfo, Repo, Block}
  alias GodwokenIndexer.Account.{UpdateInfoWorker, UpdateUDTWorker}

  @default_worker_interval 5

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @spec init(any) :: {:ok, any}
  def init(state) do
    init_godwoken_l1_block_number =
      Application.get_env(:godwoken_explorer, :init_godwoken_l1_block_number)

    start_block_number =
      case Repo.get_by(CheckInfo, type: "main_deposit") do
        %CheckInfo{tip_block_number: l1_block_number} when is_integer(l1_block_number) -> l1_block_number + 1
        nil -> init_godwoken_l1_block_number
      end

    schedule_work(start_block_number)

    {:ok, state}
  end

  def handle_cast({:manual_sync_work, block_number}, state) do
    fetch_deposition_script_and_update(block_number)
    {:noreply, state}
  end

  def handle_info({:bind_deposit_work, block_number}, state) do
    {:ok, next_block_number} = fetch_deposition_script_and_update(block_number)

    schedule_work(next_block_number)

    {:noreply, state}
  end


  def fetch_deposition_script_and_update(block_number) do
    deposition_lock = Application.get_env(:godwoken_explorer, :deposition_lock)
    check_info = Repo.get_by(CheckInfo, type: "main_deposoit")
    {:ok, response} = GodwokenRPC.fetch_l1_block(block_number)
    header = response["header"]
    block_hash = header["hash"]

    # TODO: rollback
    if forked?(header["parent_hash"], check_info) do
      Block.reset_layer1_bind_info(check_info.tip_block_number)
      # rollback account
      CheckInfo.rollback(check_info)
      throw :rollback
    end

    response["transactions"]
    |> Enum.each(fn tx ->
      tx["outputs"]
      |> Enum.with_index()
      |> Enum.each(fn {output, index} ->
        if output["lock"]["code_hash"] == deposition_lock.code_hash &&
             String.starts_with?(output["lock"]["args"], deposition_lock.args) do
          ckb_lock_script = get_ckb_lock_script(Enum.at(tx["inputs"], index))
          parse_lock_script_and_bind(output, ckb_lock_script)
        end
      end)
    end)

    CheckInfo.create_or_update_info(%{type: :main_deposit, tip_block_number: block_number,block_hash: block_hash})

    {:ok, block_number + 1}
  end

  defp parse_lock_script_and_bind(output, ckb_lock_script) do
    {l2_script_hash, l1_lock_hash} = parse_lock_args(output["lock"]["args"])
    {udt_script, udt_script_hash} = parse_udt_script(output)

    user_account =
      Account.bind_ckb_lock_script(
        ckb_lock_script,
        "0x" <> l2_script_hash,
        "0x" <> l1_lock_hash
      )

    with {:ok, udt_account_id} <- Account.find_or_create_udt_account(udt_script, udt_script_hash) do
      with {:ok, user} <- user_account do
          UpdateInfoWorker.sync_trigger_account([user.id])
          UpdateUDTWorker.sync_trigger_sudt_account([{udt_account_id, [user.id]}])
      end
    end
  end

  defp parse_udt_script(output) do
    case Map.get(output, "type") do
      nil ->
        {nil, "0x0000000000000000000000000000000000000000000000000000000000000000"}

      %{} = udt_script ->
        {udt_script, script_to_hash(udt_script)}
    end
  end

  defp parse_lock_args(args) do
    args
    |> String.slice(2..-1)
    |> parse_deposition_lock_args()
  end

  # FIXME: input length is same?
  defp get_ckb_lock_script(input) do
    %{"previous_output" => %{"index" => index, "tx_hash" => tx_hash}} = input

    with {:ok, %{"transaction" => %{"outputs" => outputs}}} <- GodwokenRPC.fetch_l1_tx(tx_hash) do
      outputs
      |> Enum.at(hex_to_number(index))
      |> Map.get("lock")
    end
    |> Map.merge(%{"name" => "secp256k1/blake160"})
  end

  defp schedule_work(start_block_number) do
    second =
      Application.get_env(:godwoken_explorer, :sync_deposition_worker_interval) ||
        @default_worker_interval

    Process.send_after(self(), {:bind_deposit_work, start_block_number}, second * 1000)
  end

  defp forked?(parent_hash, check_info) do
    if is_nil(check_info) || check_info.block_hash.blank? do
      false
    else
      parent_hash != check_info.block_hash
    end
  end
end
