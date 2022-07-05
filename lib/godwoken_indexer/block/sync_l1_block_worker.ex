defmodule GodwokenIndexer.Block.SyncL1BlockWorker do
  use GenServer

  import Godwoken.MoleculeParser,
    only: [
      parse_deposition_lock_args: 1,
      parse_v1_deposition_lock_args: 1,
      parse_withdrawal_lock_args: 1
    ]

  import GodwokenRPC.Util,
    only: [
      hex_to_number: 1,
      script_to_hash: 1,
      parse_le_number: 1,
      timestamp_to_utc_datetime: 1,
      import_timestamps: 0
    ]

  import Ecto.Query, only: [from: 2]

  require Logger

  alias GodwokenExplorer.{
    Account,
    AccountUDT,
    CheckInfo,
    Repo,
    Block,
    DepositHistory,
    WithdrawalHistory,
    UDT
  }

  @default_worker_interval 5
  @smallest_deposit_ckb_capacity 298 * :math.pow(10, 8)
  @smallest_deposit_udt_ckb_capacity 379 * :math.pow(10, 8)
  @smallest_withdrawal_ckb_capacity 266 * :math.pow(10, 8)
  @smallest_withdrawal_udt_ckb_capacity 347 * :math.pow(10, 8)

  @buffer_block_for_create_account 20

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
        {:ok, _new_block_number} = batch_fetch_l1_script_and_update(block_number)
      else
        {:ok, block_number}
      end

    schedule_work(next_block_number)

    {:noreply, state}
  end

  def batch_fetch_l1_script_and_update(block_number) do
    deposition_lock = Application.get_env(:godwoken_explorer, :deposition_lock)
    withdrawal_lock = Application.get_env(:godwoken_explorer, :withdrawal_lock)
    multiple_l1_block_once? = Application.get_env(:godwoken_explorer, :multiple_l1_block_once)
    l1_block_batch_size = Application.get_env(:godwoken_explorer, :l1_block_batch_size)

    range =
      if multiple_l1_block_once? do
        block_number..(block_number + l1_block_batch_size)
      else
        block_number..block_number
      end
      |> Enum.map(&%{block_number: &1})

    {:ok,
     %GodwokenRPC.CKBIndexer.FetchedBlocks{
       errors: [],
       params_list: block_responses
     }} = GodwokenRPC.fetch_l1_blocks(range)

    responses = block_responses |> Enum.map(&Map.fetch!(&1, :block))
    last_header = responses |> List.first() |> Map.fetch!("header")
    last_block_hash = last_header["hash"]
    last_block_number = last_header["number"] |> hex_to_number()
    check_info = Repo.get_by(CheckInfo, type: :main_deposit)

    if !multiple_l1_block_once? && forked?(last_header["parent_hash"], check_info) do
      Logger.error("!!!!!!forked!!!!!!#{block_number}")

      Repo.transaction(fn ->
        Block.reset_layer1_bind_info!(check_info.tip_block_number)
        DepositHistory.rollback!(check_info.tip_block_number)
        WithdrawalHistory.rollback!(check_info.tip_block_number)
        CheckInfo.rollback!(check_info)
      end)

      throw(:rollback)
    end

    combined_txs =
      responses
      |> Enum.flat_map(fn response ->
        response
        |> Map.fetch!("transactions")
        |> Enum.map(fn tx ->
          tx
          |> Map.merge(%{"block_number" => response["header"]["number"] |> hex_to_number()})
          |> Map.merge(%{
            "timestamp" =>
              response["header"]["timestamp"] |> hex_to_number() |> timestamp_to_utc_datetime()
          })
        end)
      end)

    deposit_txs =
      combined_txs
      |> Enum.flat_map(fn tx ->
        tx["outputs"]
        |> Enum.with_index()
        |> Enum.reduce([], fn {output, index}, acc ->
          if output["lock"]["code_hash"] == deposition_lock.code_hash &&
               output["lock"]["hash_type"] == deposition_lock.hash_type &&
               String.starts_with?(output["lock"]["args"], deposition_lock.args) &&
               ((is_nil(Map.get(output, "type")) &&
                   hex_to_number(output["capacity"]) >= @smallest_deposit_ckb_capacity) ||
                  (not is_nil(Map.get(output, "type")) &&
                     hex_to_number(output["capacity"]) >= @smallest_deposit_udt_ckb_capacity)) do
            [
              %{
                output: output,
                index: index,
                block_number: tx["block_number"],
                timestamp: tx["timestamp"],
                tx_hash: tx["hash"],
                output_data: tx["outputs_data"] |> Enum.at(index)
              }
              | acc
            ]
          else
            acc
          end
        end)
      end)

    withdrawal_txs =
      combined_txs
      |> Enum.flat_map(fn tx ->
        tx["outputs"]
        |> Enum.with_index()
        |> Enum.reduce([], fn {output, index}, acc ->
          if output["lock"]["code_hash"] == withdrawal_lock.code_hash &&
               output["lock"]["hash_type"] == withdrawal_lock.hash_type &&
               String.starts_with?(output["lock"]["args"], withdrawal_lock.args) &&
               ((is_nil(Map.get(output, "type")) &&
                   hex_to_number(output["capacity"]) >= @smallest_withdrawal_ckb_capacity) ||
                  (not is_nil(Map.get(output, "type")) &&
                     hex_to_number(output["capacity"]) >= @smallest_withdrawal_udt_ckb_capacity)) do
            [
              %{
                block_number: tx["block_number"],
                tx_hash: tx["hash"],
                index: index,
                args: output["lock"]["args"] |> String.slice(2..-1),
                timestamp: tx["timestamp"],
                output_data: tx["outputs_data"] |> Enum.at(index),
                output: output
              }
              | acc
            ]
          else
            acc
          end
        end)
      end)

    if deposit_txs != [],
      do:
        deposit_txs
        |> parse_deposit_txs()
        |> import_deposits()
        |> elem(1)
        |> import_eoa_accounts()

    if withdrawal_txs != [], do: withdrawal_txs |> parse_withdrawal_txs() |> import_withdrawals()

    CheckInfo.create_or_update_info(%{
      type: :main_deposit,
      tip_block_number: last_block_number,
      block_hash: last_block_hash
    })

    {:ok, last_block_number + 1}
  end

  def parse_withdrawal_txs(withdrawal_txs) do
    parsed_withdrawal_histories =
      withdrawal_txs
      |> Enum.map(fn %{
                       block_number: block_number,
                       tx_hash: tx_hash,
                       index: index,
                       args: args,
                       timestamp: timestamp,
                       output_data: output_data,
                       output: output
                     } ->
        {
          l2_script_hash,
          {l2_block_hash, l2_block_number},
          {_sudt_script_hash, sell_amount, sell_capacity},
          owner_lock_hash,
          payment_lock_hash
        } = parse_withdrawal_lock_args(args |> String.slice(0..447))

        capacity = hex_to_number(output["capacity"])
        {_udt_script, udt_script_hash, amount} = parse_udt_script(output, output_data, capacity)

        %{
          is_fast_withdrawal: fast_withdrawal?(args),
          layer1_block_number: block_number,
          layer1_tx_hash: tx_hash,
          layer1_output_index: index,
          l2_script_hash: "0x" <> l2_script_hash,
          block_hash: "0x" <> l2_block_hash,
          block_number: l2_block_number,
          udt_script_hash: udt_script_hash,
          sell_amount: sell_amount |> parse_le_number,
          sell_capacity: sell_capacity,
          owner_lock_hash: "0x" <> owner_lock_hash,
          payment_lock_hash: "0x" <> payment_lock_hash,
          timestamp: timestamp,
          amount: amount,
          capacity: capacity
        }
      end)

    udt_script_hash_with_ids = list_udt_script_hash_and_udt_id(parsed_withdrawal_histories)

    parsed_withdrawal_histories
    |> Enum.map(fn wh ->
      wh
      |> Map.merge(%{udt_id: Map.fetch!(udt_script_hash_with_ids, wh[:udt_script_hash])})
      |> Map.merge(import_timestamps())
    end)
  end

  defp list_udt_script_hash_and_udt_id(parsed_histories) do
    parsed_histories
    |> Enum.uniq_by(&Map.fetch!(&1, :udt_script_hash))
    |> Enum.map(&Map.fetch!(&1, :udt_script_hash))
    |> UDT.list_bridge_token_by_udt_script_hashes()
    |> Enum.into(%{}, fn {k, v} -> {k, v} end)
  end

  defp import_withdrawals(withdrawal_histories) do
    Repo.insert_all(WithdrawalHistory, withdrawal_histories, on_conflict: :nothing)
  end

  defp parse_deposit_txs(deposit_txs) do
    parsed_deposit_histories =
      deposit_txs
      |> Enum.map(fn %{
                       output: output,
                       block_number: l1_block_number,
                       index: index,
                       timestamp: timestamp,
                       tx_hash: tx_hash,
                       output_data: output_data
                     } ->
        capacity = hex_to_number(output["capacity"])
        [script_hash, l1_lock_hash] = parse_lock_args(output["lock"]["args"])
        {udt_script, udt_script_hash, amount} = parse_udt_script(output, output_data, capacity)

        %{
          layer1_block_number: l1_block_number,
          layer1_tx_hash: tx_hash,
          layer1_output_index: index,
          timestamp: timestamp,
          udt_script_hash: udt_script_hash,
          udt_script: udt_script,
          amount: amount,
          ckb_lock_hash: l1_lock_hash,
          script_hash: script_hash,
          capacity: capacity
        }
      end)

    import_udts(parsed_deposit_histories)
    udt_script_hash_with_ids = list_udt_script_hash_and_udt_id(parsed_deposit_histories)

    parsed_deposit_histories
    |> Enum.map(fn dh ->
      dh
      |> Map.merge(%{udt_id: Map.fetch!(udt_script_hash_with_ids, dh[:udt_script_hash])})
      |> Map.delete(:udt_script)
      |> Map.delete(:udt_script_hash)
      |> Map.merge(import_timestamps())
    end)
  end

  defp import_deposits(deposit_histories) do
    Repo.insert_all(DepositHistory, deposit_histories,
      on_conflict: :nothing,
      returning: [:script_hash, :udt_id]
    )
  end

  def import_eoa_accounts(deposit_histories) do
    if deposit_histories != [] do
      script_hashes_and_udt_id =
        deposit_histories |> Enum.map(&{Map.fetch!(&1, :script_hash), Map.fetch!(&1, :udt_id)})

      script_hashes_and_udt_id_map =
        script_hashes_and_udt_id |> Enum.uniq() |> Enum.into(%{}, fn {k, v} -> {k, v} end)

      script_hashes = Map.keys(script_hashes_and_udt_id_map)

      exist_script_hashes =
        from(a in Account, where: a.script_hash in ^script_hashes, select: a.script_hash)
        |> Repo.all()

      not_exist_script_hashes = script_hashes -- exist_script_hashes
      Account.batch_import_accounts_with_script_hashes(not_exist_script_hashes)

      script_hash_short_address =
        from(a in Account,
          where: a.script_hash in ^script_hashes,
          select: {a.script_hash, a.short_address}
        )
        |> Repo.all()
        |> Enum.into(%{}, fn {k, v} -> {k, v} end)

      params =
        script_hashes_and_udt_id_map
        |> Enum.map(fn {script_hash, udt_id} ->
          %{
            short_address: Map.fetch!(script_hash_short_address, script_hash),
            udt_id: udt_id,
            token_contract_address_hash: nil
          }
        end)

      {:ok, %GodwokenRPC.Account.FetchedBalances{params_list: import_account_udts}} =
        GodwokenRPC.fetch_balances(params)

      import_account_udts =
        import_account_udts
        |> Enum.map(fn import_au -> import_au |> Map.merge(import_timestamps()) end)

      Repo.insert_all(AccountUDT, import_account_udts,
        on_conflict: {:replace, [:balance, :updated_at]},
        conflict_target: [:address_hash, :token_contract_address_hash]
      )
    end
  end

  defp import_udts(parsed_deposit_histories) do
    parsed_deposit_histories
    |> Enum.uniq_by(&Map.fetch!(&1, :udt_script_hash))
    |> Enum.map(&{Map.fetch!(&1, :udt_script_hash), Map.fetch!(&1, :udt_script)})
    |> UDT.filter_not_exist_udts()
    |> Account.import_udt_account()
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
    try do
      args
      |> String.slice(2..-1)
      |> parse_deposition_lock_args()
      |> Tuple.to_list()
      |> Enum.map(fn x ->
        "0x" <> x
      end)
    rescue
      ErlangError ->
        args
        |> String.slice(2..-1)
        |> parse_v1_deposition_lock_args()
        |> Tuple.to_list()
        |> Enum.map(fn x ->
          "0x" <> x
        end)
    end
  end

  defp schedule_work(start_block_number) do
    second =
      Application.get_env(:godwoken_explorer, :sync_deposition_worker_interval) ||
        @default_worker_interval

    Process.send_after(self(), {:bind_deposit_work, start_block_number}, second * 1000)
  end

  defp fast_withdrawal?(args) do
    if String.length(args) == 448 do
      false
    else
      try do
        owner_lock_length = args |> String.slice(448..455) |> hex_to_number
        args |> String.slice((456 + owner_lock_length * 2)..-1) == "01"
      rescue
        _ -> false
      end
    end
  end

  defp forked?(parent_hash, check_info) do
    if is_nil(check_info) || is_nil(check_info.block_hash) do
      false
    else
      parent_hash != check_info.block_hash
    end
  end
end
