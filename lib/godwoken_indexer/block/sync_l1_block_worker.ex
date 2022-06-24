defmodule GodwokenIndexer.Block.SyncL1BlockWorker do
  use GenServer

  import Godwoken.MoleculeParser,
    only: [parse_deposition_lock_args: 1, parse_withdrawal_lock_args: 1]

  import GodwokenRPC.Util,
    only: [hex_to_number: 1, script_to_hash: 1, parse_le_number: 1, timestamp_to_datetime: 1]

  require Logger
  require IEx

  alias GodwkenRPC

  alias GodwokenExplorer.{
    Account,
    CheckInfo,
    Repo,
    Block,
    DepositHistory,
    AccountUDT,
    WithdrawalHistory,
    UDT
  }

  @default_worker_interval 5
  @smallest_ckb_capacity 290 * :math.pow(10, 8)
  @smallest_udt_ckb_capacity 371 * :math.pow(10, 8)
  @buffer_block_for_create_account 20
  @biggest_buffer_block_for_create_account 30

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @spec init(any) :: {:ok, any}
  def init(state) do
    init_godwoken_l1_block_number =
      Application.get_env(:godwoken_explorer, :init_godwoken_l1_block_number)

    start_block_number =
      case Repo.get_by(CheckInfo, type: "main_deposit") do
        %CheckInfo{tip_block_number: l1_block_number} when is_integer(l1_block_number) ->
          l1_block_number + 1

        nil ->
          init_godwoken_l1_block_number
      end

    schedule_work(start_block_number)

    {:ok, state}
  end

  def handle_info({:bind_deposit_work, block_number}, state) do
    {:ok, l1_tip_number} = GodwokenRPC.fetch_l1_tip_block_nubmer()

    {:ok, next_block_number} =
      if block_number + @buffer_block_for_create_account <= l1_tip_number do
        {:ok, _new_block_number} = fetch_deposition_script_and_update(block_number, l1_tip_number)
      else
        {:ok, block_number}
      end

    schedule_work(next_block_number)

    {:noreply, state}
  end

  def fetch_deposition_script_and_update(block_number, l1_tip_number) do
    deposition_lock = Application.get_env(:godwoken_explorer, :deposition_lock)
    withdrawal_lock = Application.get_env(:godwoken_explorer, :withdrawal_lock)
    check_info = Repo.get_by(CheckInfo, type: :main_deposit)
    {:ok, response} = GodwokenRPC.fetch_l1_block(block_number)
    header = response["header"]
    block_hash = header["hash"]

    timestamp = header["timestamp"] |> hex_to_number() |> timestamp_to_datetime

    if forked?(header["parent_hash"], check_info) do
      Logger.error("!!!!!!forked!!!!!!#{block_number}")

      Repo.transaction(fn ->
        Block.reset_layer1_bind_info!(check_info.tip_block_number)
        DepositHistory.rollback!(check_info.tip_block_number)
        WithdrawalHistory.rollback!(check_info.tip_block_number)
        CheckInfo.rollback!(check_info)
      end)

      throw(:rollback)
    end

    response["transactions"]
    |> Enum.each(fn tx ->
      tx["outputs"]
      |> Enum.with_index()
      |> Enum.each(fn {output, index} ->
        if output["lock"]["code_hash"] == deposition_lock.code_hash &&
             output["lock"]["hash_type"] == deposition_lock.hash_type &&
             String.starts_with?(output["lock"]["args"], deposition_lock.args) &&
             ((is_nil(Map.get(output, "type")) &&
                 hex_to_number(output["capacity"]) >= @smallest_ckb_capacity) ||
                (not is_nil(Map.get(output, "type")) &&
                   hex_to_number(output["capacity"]) >= @smallest_udt_ckb_capacity)) do
          parse_lock_args_and_bind(%{
            output: output,
            index: index,
            block_number: block_number,
            timestamp: timestamp,
            tx_hash: tx["hash"],
            output_data: tx["outputs_data"] |> Enum.at(index),
            tip_block_number: l1_tip_number
          })
        end

        if output["lock"]["code_hash"] == withdrawal_lock.code_hash &&
             output["lock"]["hash_type"] == withdrawal_lock.hash_type &&
             String.starts_with?(output["lock"]["args"], withdrawal_lock.args) do
          parse_withdrawal_lock_args_and_save(%{
            block_number: block_number,
            tx_hash: tx["hash"],
            index: index,
            args: output["lock"]["args"] |> String.slice(2..-1),
            timestamp: timestamp,
            output_data: tx["outputs_data"] |> Enum.at(index),
            output: output,
            tip_block_number: l1_tip_number
          })
        end
      end)
    end)

    CheckInfo.create_or_update_info(%{
      type: :main_deposit,
      tip_block_number: block_number,
      block_hash: block_hash
    })

    {:ok, block_number + 1}
  end

  defp parse_withdrawal_lock_args_and_save(%{
         block_number: block_number,
         tx_hash: tx_hash,
         index: index,
         args: args,
         timestamp: timestamp,
         output_data: output_data,
         output: output,
         tip_block_number: l1_tip_number
       }) do
    try do
      {
        l2_script_hash,
        {l2_block_hash, l2_block_number},
        owner_lock_hash
      } = parse_withdrawal_lock_args(String.slice(args, 0..271))

      capacity = hex_to_number(output["capacity"])
      {udt_script, udt_script_hash, amount} = parse_udt_script(output, output_data, capacity)

      with {:ok, udt_id} <-
             Account.find_or_create_udt_account!(
               udt_script,
               udt_script_hash,
               block_number,
               l1_tip_number
             ) do
        WithdrawalHistory.create_or_update_history!(%{
          layer1_block_number: block_number,
          layer1_tx_hash: tx_hash,
          layer1_output_index: index,
          l2_script_hash: "0x" <> l2_script_hash,
          block_hash: "0x" <> l2_block_hash,
          block_number: l2_block_number,
          udt_script_hash: udt_script_hash,
          owner_lock_hash: "0x" <> owner_lock_hash,
          timestamp: timestamp,
          udt_id: udt_id,
          amount: amount,
          capacity: capacity
        })
      end
    rescue
      e -> Sentry.capture_exception(e, extra: %{l1_tx_hash: tx_hash, index: index})
    end
  end

  defp parse_lock_args_and_bind(%{
         output: output,
         block_number: l1_block_number,
         index: index,
         timestamp: timestamp,
         tx_hash: tx_hash,
         output_data: output_data,
         tip_block_number: tip_block_number
       }) do
    try do
      [script_hash, l1_lock_hash] = parse_lock_args(output["lock"]["args"])
      capacity = hex_to_number(output["capacity"])
      {udt_script, udt_script_hash, amount} = parse_udt_script(output, output_data, capacity)

      account =
        case Repo.get_by(Account, script_hash: script_hash) do
          nil ->
            case GodwokenRPC.fetch_account_id(script_hash) do
              {:error, :account_slow} ->
                if l1_block_number + @biggest_buffer_block_for_create_account > tip_block_number do
                  raise "account #{script_hash} may not created now at #{l1_block_number} #{tx_hash} #{index}"
                end

              {:error, :network_error} ->
                raise "account #{script_hash} fetch account_id network error"

              {:ok, account_id} ->
                nonce = GodwokenRPC.fetch_nonce(account_id)
                {:ok, script} = GodwokenRPC.fetch_script(script_hash)
                type = Account.switch_account_type(script["code_hash"], script["args"])
                eth_address = Account.script_to_eth_adress(type, script["args"])
                registry_address = Account.eth_address_to_registry_address(eth_address)

                {:ok, account} =
                  Account.create_or_update_account!(%{
                    id: account_id,
                    script: script,
                    script_hash: script_hash,
                    registry_address: registry_address,
                    type: type,
                    nonce: nonce,
                    eth_address: eth_address
                  })

                account
            end

          account when account != nil ->
            account
        end

      {:ok, udt_id} =
        Account.find_or_create_udt_account!(
          udt_script,
          udt_script_hash,
          l1_block_number,
          tip_block_number
        )

      DepositHistory.create_or_update_history!(%{
        layer1_block_number: l1_block_number,
        layer1_tx_hash: tx_hash,
        layer1_output_index: index,
        timestamp: timestamp,
        udt_id: udt_id,
        amount: amount,
        ckb_lock_hash: l1_lock_hash,
        script_hash: script_hash,
        capacity: capacity
      })

      if udt_id != UDT.ckb_account_id(),
        do: AccountUDT.sync_balance!(%{account_id: account.id, udt_id: udt_id})

      AccountUDT.sync_balance!(%{account_id: account.id, udt_id: UDT.ckb_account_id()})
    rescue
      ErlangError ->
        Logger.error("DepositLockArgs parse error: #{tx_hash} #{index}")
        {:error, :v1_1_deposit}
    end
  end

  defp parse_udt_script(output, output_data, capacity) do
    case Map.get(output, "type") do
      nil ->
        {nil, "0x0000000000000000000000000000000000000000000000000000000000000000", capacity}

      %{} = udt_script ->
        {udt_script, script_to_hash(udt_script),
         output_data |> String.slice(2..-1) |> parse_le_number}
    end
  end

  defp parse_lock_args(args) do
    args
    |> String.slice(2..-1)
    |> parse_deposition_lock_args()
    |> Tuple.to_list()
    |> Enum.map(fn x ->
      "0x" <> x
    end)
  end

  defp schedule_work(start_block_number) do
    second =
      Application.get_env(:godwoken_explorer, :sync_deposition_worker_interval) ||
        @default_worker_interval

    Process.send_after(self(), {:bind_deposit_work, start_block_number}, second * 1000)
  end

  defp forked?(parent_hash, check_info) do
    if is_nil(check_info) || is_nil(check_info.block_hash) do
      false
    else
      parent_hash != check_info.block_hash
    end
  end
end
