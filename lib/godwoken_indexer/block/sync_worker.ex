defmodule GodwokenIndexer.Block.SyncWorker do
  @moduledoc """
  Sync layer2 block worker and parse polyjuice receipt.
  """

  use GenServer

  import GodwokenRPC.Util,
    only: [import_timestamps: 0, import_utc_timestamps: 0, script_to_hash: 1]

  import Ecto.Query, only: [from: 2]

  require Logger

  alias GodwokenIndexer.Worker.{CheckContractUDT, ImportContractCode}
  alias GodwokenIndexer.Transform.{TokenTransfers, TokenBalances, TokenApprovals}
  alias GodwokenRPC.{Blocks, Receipts}
  alias GodwokenExplorer.Chain.Import
  alias GodwokenExplorer.GW.Log, as: GWLog
  alias GodwokenExplorer.GW.{SudtPayFee, SudtTransfer}
  alias GodwokenExplorer.GlobalConstants

  alias GodwokenExplorer.{
    Address,
    Block,
    Transaction,
    Repo,
    Account,
    WithdrawalRequest,
    Log,
    TokenApproval,
    TokenTransfer,
    Polyjuice,
    PolyjuiceCreator,
    UDT
  }

  alias GodwokenExplorer.Account.{UDTBalance, CurrentBridgedUDTBalance}

  alias GodwokenExplorer.Chain.Cache.Blocks, as: BlocksCache
  alias GodwokenExplorer.Chain.Cache.Transactions

  alias GodwokenExplorer.Chain.Hash
  alias GodwokenIndexer.Worker.ERC721ERC1155InstanceMetadata
  alias GodwokenExplorer.Graphql.Workers.UpdateSmartContractCKB

  @default_worker_interval 20

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    next_block_number = get_next_block_number()
    schedule_work(next_block_number)

    {:ok, state}
  end

  @impl true
  def handle_info({:work, next_block_number}, state) do
    {:ok, block_number} =
      if under_tip_block?(next_block_number) do
        {:ok, _} = fetch_and_import(next_block_number)
      else
        {:ok, next_block_number}
      end

    schedule_work(block_number)

    {:noreply, state}
  end

  @spec fetch_and_import(GodwokenRPC.block_number()) :: {:ok, GodwokenRPC.block_number()}
  def fetch_and_import(next_block_number) do
    multiple_block_once? = Application.get_env(:godwoken_explorer, :multiple_block_once)
    block_batch_size = Application.get_env(:godwoken_explorer, :block_batch_size)

    range =
      if multiple_block_once? do
        next_block_number..(next_block_number + block_batch_size)
      else
        next_block_number..next_block_number
      end

    {:ok,
     %Blocks{
       blocks_params: blocks_params,
       transactions_params: transactions_params_without_receipts,
       withdrawal_params: withdrawal_params,
       errors: []
     }} = rpc().fetch_blocks_by_range(range)

    if is_nil(multiple_block_once?) do
      {:ok, _} = validate_last_block_fork(blocks_params, next_block_number)
    end

    if transactions_params_without_receipts != [] do
      import_account(transactions_params_without_receipts)
      handle_gw_transaction_receipts(transactions_params_without_receipts, next_block_number)

      {polyjuice_without_receipts, polyjuice_creator_params, eth_addr_reg_params} =
        group_transaction_params(transactions_params_without_receipts)

      polyjuice_with_eth_hashes_params =
        handle_polyjuice_transactions(polyjuice_without_receipts)
        |> add_method_id_and_name_to_tx_params()

      import_polyjuice_creator(polyjuice_creator_params)

      inserted_transactions =
        import_transactions(
          blocks_params,
          polyjuice_creator_params ++ eth_addr_reg_params ++ polyjuice_with_eth_hashes_params
        )

      update_transactions_cache(inserted_transactions)
    end

    import_withdrawal_requests(withdrawal_params, next_block_number)
    inserted_blocks = import_block(blocks_params)
    update_block_cache(inserted_blocks)

    if multiple_block_once? do
      {:ok, next_block_number + block_batch_size + 1}
    else
      {:ok, next_block_number + 1}
    end
  end

  defp handle_gw_transaction_receipts(transaction_params, block_number) do
    gw_hashes = transaction_params |> Enum.map(&Map.take(&1, [:hash]))

    {:ok, %{logs: logs, sudt_transfers: sudt_transfers, sudt_pay_fees: sudt_pay_fees}} =
      rpc().fetch_gw_transaction_receipts(gw_hashes)

    import_gw_logs(logs)
    {_, sudt_transfers} = import_sudt_transfers(sudt_transfers)
    {_, sudt_pay_fees} = import_sudt_pay_fees(sudt_pay_fees)

    transfer_account_udts =
      (sudt_transfers || [])
      |> Enum.reduce(MapSet.new(), fn transfer, map_set ->
        map_set
        |> MapSet.put(%{address: transfer.from_address, udt_id: transfer.udt_id})
        |> MapSet.put(%{address: transfer.to_address, udt_id: transfer.udt_id})
      end)
      |> MapSet.to_list()

    pay_fee_account_udts =
      (sudt_pay_fees || [])
      |> Enum.reduce(MapSet.new(), fn transfer, map_set ->
        map_set
        |> MapSet.put(%{address: transfer.from_address, udt_id: transfer.udt_id})
        |> MapSet.put(%{address: transfer.block_producer_address, udt_id: transfer.udt_id})
      end)
      |> MapSet.to_list()

    account_udts = transfer_account_udts ++ pay_fee_account_udts
    udt_ids = account_udts |> Enum.map(&Map.get(&1, :udt_id)) |> Enum.uniq()

    exist_udt_ids = from(a in Account, where: a.id in ^udt_ids, select: a.id) |> Repo.all()
    not_exist_udt_ids = udt_ids -- exist_udt_ids
    Account.batch_import_accounts_with_ids(not_exist_udt_ids)

    udt_id_script_hashes =
      from(a in Account, where: a.id in ^udt_ids, select: %{id: a.id, script_hash: a.script_hash})
      |> Repo.all()

    params =
      account_udts
      |> Enum.map(fn %{address: address, udt_id: udt_id} ->
        udt = udt_id_script_hashes |> Enum.find(fn account -> account[:id] == udt_id end)

        %{
          registry_address: address |> to_string() |> Account.eth_address_to_registry_address(),
          account_id: nil,
          udt_id: udt_id,
          udt_script_hash: to_string(udt.script_hash),
          eth_address: address
        }
      end)
      |> Enum.uniq()

    {:ok, %GodwokenRPC.Account.FetchedBalances{params_list: import_account_udts}} =
      rpc().fetch_balances(params)

    import_account_udts =
      import_account_udts
      |> Enum.uniq_by(&{Map.fetch!(&1, :address_hash), Map.fetch!(&1, :udt_id)})
      |> Enum.map(&Map.put(&1, :block_number, block_number))

    import_account_udts
    |> UpdateSmartContractCKB.update_smart_contract_with_ckb_balance()

    Import.insert_changes_list(
      import_account_udts,
      for: CurrentBridgedUDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: {:replace, [:block_number, :value, :updated_at]},
      conflict_target: [:address_hash, :udt_script_hash]
    )
  end

  defp handle_polyjuice_transactions(polyjuice_without_receipts) do
    if polyjuice_without_receipts != [] do
      params =
        polyjuice_without_receipts
        |> Enum.map(fn polyjuice -> %{gw_tx_hash: polyjuice[:hash]} end)

      {:ok, %{errors: [], params_list: hash_mappings}} = rpc().fetch_eth_hash_by_gw_hashes(params)

      hash_map = hash_mappings |> Enum.into(%{}, fn map -> {map[:gw_tx_hash], map[:eth_hash]} end)

      polyjuice_without_receipts =
        polyjuice_without_receipts
        |> Enum.map(fn polyjuice ->
          polyjuice |> Map.put(:eth_hash, hash_map[polyjuice[:hash]])
        end)

      {:ok, %{logs: logs, receipts: receipts}} =
        rpc().fetch_transaction_receipts(polyjuice_without_receipts)

      logs = logs |> Enum.reject(fn x -> x[:first_topic] == nil end)
      import_logs(logs)
      import_token_transfers(logs)
      import_token_approvals(logs)
      polyjuice_with_receipts = Receipts.put(polyjuice_without_receipts, receipts)

      handle_tx_generated_contract(polyjuice_with_receipts)
      import_polyjuice(polyjuice_with_receipts)
      async_contract_code(polyjuice_with_receipts)

      if length(polyjuice_without_receipts) > 0,
        do: {:ok, :import} = update_ckb_balance(polyjuice_without_receipts)

      polyjuice_without_receipts
    else
      []
    end
  end

  defp import_gw_logs(gw_logs) do
    Import.insert_changes_list(
      gw_logs,
      for: GWLog,
      timestamps: import_timestamps(),
      on_conflict: :nothing
    )
  end

  defp import_sudt_transfers(sudt_transfers) do
    Import.insert_changes_list(
      sudt_transfers,
      for: SudtTransfer,
      timestamps: import_timestamps(),
      on_conflict: :nothing,
      returning: [
        :from_address,
        :to_address,
        :udt_id
      ]
    )
  end

  defp import_sudt_pay_fees(sudt_pay_fees) do
    Import.insert_changes_list(
      sudt_pay_fees,
      for: SudtPayFee,
      timestamps: import_timestamps(),
      on_conflict: :nothing,
      returning: [
        :from_address,
        :block_producer_address,
        :udt_id
      ]
    )
  end

  defp async_contract_code(polyjuice_with_receipts) do
    polyjuice_with_receipts
    |> Enum.filter(fn attrs ->
      attrs[:created_contract_address_hash] != nil and attrs[:status] != :failed
    end)
    |> Enum.each(fn attrs ->
      %{block_number: attrs[:block_number], address: attrs[:created_contract_address_hash]}
      |> ImportContractCode.new()
      |> Oban.insert()
    end)
  end

  defp group_transaction_params(transactions_params_without_receipts) do
    grouped = transactions_params_without_receipts |> Enum.group_by(fn tx -> tx[:type] end)

    {grouped[:polyjuice] || [], grouped[:polyjuice_creator] || [],
     grouped[:eth_address_registry] || []}
  end

  @spec under_tip_block?(GodwokenRPC.block_number()) :: boolean
  defp under_tip_block?(block_number) do
    case GodwokenRPC.fetch_tip_block_number() do
      {:ok, tip_number} ->
        block_number <= tip_number

      {:error, msg} ->
        Logger.error("Fetch Tip Block Number Failed: #{inspect(msg)}")
        false
    end
  end

  @spec validate_last_block_fork(list, GodwokenRPC.block_number()) ::
          {:ok, :normal} | {:error, :forked}
  defp validate_last_block_fork(blocks_params, next_block_number) do
    parent_hash =
      blocks_params
      |> List.first()
      |> Map.get(:parent_hash)

    if forked?(parent_hash, next_block_number - 1) do
      Logger.error("!!!!!!Layer2 forked!!!!!!#{next_block_number - 1}")
      Block.rollback!(parent_hash)
      {:error, :forked}
    else
      {:ok, :normal}
    end
  end

  @spec import_block(list) :: list
  defp import_block(blocks_params) do
    {_count, returned_values} =
      Import.insert_changes_list(
        blocks_params,
        for: Block,
        timestamps: import_timestamps(),
        on_conflict: :nothing,
        returning: [:hash, :number, :transaction_count, :size, :timestamp]
      )

    returned_values
  end

  defp import_logs(logs) do
    Import.insert_changes_list(logs,
      for: Log,
      timestamps: import_timestamps(),
      on_conflict: :nothing
    )
  end

  defp import_token_approvals(logs) do
    %{
      approval_erc20: erc20_approval_params,
      approval_erc721: erc721_approval_params,
      approval_all_tokens: approval_all_tokens
    } = TokenApprovals.parse(logs)

    if length(erc20_approval_params) > 0 do
      Import.insert_changes_list(
        uniq_token_approval_params(erc20_approval_params, [
          :token_owner_address_hash,
          :spender_address_hash,
          :token_contract_address_hash
        ]),
        for: TokenApproval,
        timestamps: import_timestamps(),
        on_conflict:
          {:replace,
           [:block_hash, :block_number, :transaction_hash, :approved, :data, :updated_at]},
        conflict_target:
          {:unsafe_fragment,
           ~s<(token_owner_address_hash, token_contract_address_hash, spender_address_hash) WHERE token_type = 'erc20'>}
      )
    end

    if length(erc721_approval_params) > 0 do
      Import.insert_changes_list(
        uniq_token_approval_params(erc721_approval_params, [
          :token_owner_address_hash,
          :token_contract_address_hash,
          :data
        ]),
        for: TokenApproval,
        timestamps: import_timestamps(),
        on_conflict:
          {:replace,
           [
             :block_hash,
             :block_number,
             :transaction_hash,
             :approved,
             :spender_address_hash,
             :updated_at
           ]},
        conflict_target:
          {:unsafe_fragment,
           ~s<(token_owner_address_hash, token_contract_address_hash, data) WHERE token_type = 'erc721'>}
      )
    end

    if length(approval_all_tokens) > 0 do
      Import.insert_changes_list(
        uniq_token_approval_params(approval_all_tokens, [
          :token_owner_address_hash,
          :token_contract_address_hash
        ]),
        for: TokenApproval,
        timestamps: import_timestamps(),
        on_conflict:
          {:replace,
           [
             :block_hash,
             :block_number,
             :transaction_hash,
             :approved,
             :spender_address_hash,
             :data,
             :updated_at
           ]},
        conflict_target:
          {:unsafe_fragment,
           ~s<(token_owner_address_hash, token_contract_address_hash ) WHERE type = 'approval_all'>}
      )
    end
  end

  defp uniq_token_approval_params(params, uniq_columns) do
    params
    |> Enum.uniq_by(&Map.take(&1, uniq_columns))
  end

  defp import_token_transfers(logs) do
    %{token_transfers: token_transfers, tokens: tokens} = TokenTransfers.parse(logs)

    if length(token_transfers) > 0 do
      Import.insert_changes_list(token_transfers,
        for: TokenTransfer,
        timestamps: import_timestamps(),
        on_conflict: :nothing
      )

      update_udt_balance(token_transfers)
      update_udt_token_instance_metadata(token_transfers)
      import_addresses(token_transfers)
    end

    if length(tokens) > 0 do
      uniq_tokens = Enum.uniq(tokens)

      contract_address_hashes =
        uniq_tokens
        |> Enum.map(fn %{contract_address_hash: contract_address_hash} ->
          contract_address_hash
        end)

      exist_contract_addresses =
        from(u in UDT,
          where: u.contract_address_hash in ^contract_address_hashes,
          select: fragment("'0x' || encode(?, 'hex')", u.contract_address_hash)
        )
        |> Repo.all()

      not_exist_contract_address = contract_address_hashes -- exist_contract_addresses

      if length(not_exist_contract_address) > 0 do
        not_exist_contract_address
        |> Enum.each(fn address ->
          Account.find_or_create_contract_by_eth_address(address)
        end)

        eth_address_to_ids =
          from(a in Account,
            where: a.eth_address in ^not_exist_contract_address,
            select: {fragment("'0x' || encode(?, 'hex')", a.eth_address), a.id}
          )
          |> Repo.all()
          |> Enum.into(%{})

        token_params =
          uniq_tokens
          |> Enum.filter(fn token ->
            token[:contract_address_hash] in not_exist_contract_address
          end)
          |> Enum.map(fn token ->
            token
            |> Map.merge(%{
              id: eth_address_to_ids[token[:contract_address_hash]],
              type: :native
            })
          end)

        {_, udts} =
          Import.insert_changes_list(token_params,
            for: UDT,
            timestamps: import_timestamps(),
            on_conflict: :nothing,
            returning: [
              :contract_address_hash
            ]
          )

        udts
        |> Enum.each(fn %{contract_address_hash: contract_address_hash} ->
          %{address_hash: contract_address_hash}
          |> GodwokenIndexer.Worker.UpdateUDTInfo.new()
          |> Oban.insert()
        end)
      end
    end
  end

  defp import_addresses(token_transfers) do
    to_addresses =
      token_transfers |> Enum.map(fn %{to_address_hash: to_address} -> to_address end)

    exist_addresses =
      from(a in Account,
        where: a.eth_address in ^to_addresses,
        select: fragment("'0x' || encode(?, 'hex')", a.eth_address)
      )
      |> Repo.all()

    address_params =
      (to_addresses -- exist_addresses) |> Enum.map(fn address -> %{eth_address: address} end)

    Import.insert_changes_list(address_params,
      for: Address,
      timestamps: import_timestamps(),
      on_conflict: :nothing
    )
  end

  def add_method_id_and_name_to_tx_params(txs_params) do
    {txs_hashes, txs_to_account_ids} =
      Enum.map(txs_params, fn tx ->
        {:ok, r} = Hash.Full.cast(tx.hash)
        {r, tx.to_account_id}
      end)
      |> Enum.unzip()

    txs_to_account_ids =
      txs_to_account_ids
      |> Enum.uniq()

    polyjuices = from(p in Polyjuice, where: p.tx_hash in ^txs_hashes) |> Repo.all()

    accounts =
      from(a in Account, where: a.id in ^txs_to_account_ids and a.type == :polyjuice_contract)
      |> Repo.all()

    Enum.map(txs_params, fn tx ->
      {method_id, method_name} =
        if Enum.find(accounts, fn a ->
             a.id == tx.to_account_id
           end) do
          p =
            Enum.find(polyjuices, fn p ->
              ptx = p.tx_hash |> to_string
              tx.hash == ptx
            end)

          with p when not is_nil(p) <- p,
               input <- p.input |> to_string(),
               mid <- input |> to_string() |> String.slice(0, 10),
               true <- String.length(mid) >= 10 do
            method_name = Polyjuice.get_method_name(tx.to_account_id, input)
            {mid, method_name}
          else
            _ ->
              {"0x00", nil}
          end
        else
          {"0x00", nil}
        end

      tx
      |> Map.put(:method_id, method_id)
      |> Map.put(:method_name, method_name)
    end)
  end

  defp import_transactions(block_params, transactions_params_without_receipts) do
    inserted_transaction_params = filter_transaction_columns(transactions_params_without_receipts)

    {_count, returned_values} =
      Import.insert_changes_list(inserted_transaction_params,
        for: Transaction,
        timestamps: import_timestamps(),
        conflict_target: :hash,
        on_conflict:
          {:replace,
           [
             :block_hash,
             :from_account_id,
             :block_number,
             :eth_hash,
             :index,
             :updated_at,
             :method_id,
             :method_name
           ]},
        returning: [
          :from_account_id,
          :to_account_id,
          :hash,
          :eth_hash,
          :type,
          :block_number
        ]
      )

    display_ids =
      transactions_params_without_receipts
      |> extract_account_ids()
      |> Account.display_ids()

    returned_values
    |> Enum.map(fn tx ->
      hash =
        if tx.eth_hash != nil do
          tx.eth_hash
        else
          tx.hash
        end

      tx
      |> Map.merge(%{
        hash: hash,
        from: display_ids |> Map.get(tx.from_account_id, {tx.from_account_id}) |> elem(0),
        to: display_ids |> Map.get(tx.to_account_id, {tx.to_account_id}) |> elem(0),
        to_alias:
          display_ids
          |> Map.get(tx.to_account_id, {tx.to_account_id, tx.to_account_id})
          |> elem(1),
        timestamp: block_params |> List.first() |> Map.get(:timestamp)
      })
    end)
  end

  defp handle_tx_generated_contract(polyjuice_with_receipts) do
    created_contract_address_params =
      polyjuice_with_receipts
      |> Enum.filter(fn p -> not is_nil(p.created_contract_address_hash) end)

    if created_contract_address_params != [] do
      created_contract_address_params
      |> Enum.filter(fn p -> p.status == :succeed end)
      |> Enum.each(fn p ->
        Account.find_or_create_contract_by_eth_address(p.created_contract_address_hash)

        %{address: p.created_contract_address_hash}
        |> CheckContractUDT.new()
        |> Oban.insert()
      end)
    end
  end

  defp import_polyjuice(polyjuice_with_receipts) do
    inserted_polyjuice_params = filter_polyjuice_columns(polyjuice_with_receipts)

    Import.insert_changes_list(inserted_polyjuice_params,
      for: Polyjuice,
      timestamps: import_timestamps(),
      conflict_target: :tx_hash,
      on_conflict:
        {:replace,
         [
           :gas_used,
           :transaction_index,
           :status,
           :created_contract_address_hash,
           :native_transfer_address_hash,
           :updated_at
         ]}
    )
  end

  defp import_withdrawal_requests(withdrawal_params, block_number) do
    if withdrawal_params != [] do
      Import.insert_changes_list(withdrawal_params,
        for: WithdrawalRequest,
        timestamps: import_timestamps(),
        on_conflict: :nothing
      )

      account_script_hashes =
        withdrawal_params
        |> Enum.map(fn %{account_script_hash: account_script_hash} -> account_script_hash end)

      udt_ids =
        withdrawal_params
        |> Enum.map(fn %{udt_id: udt_id} -> udt_id end)
        |> Enum.uniq()

      udt_ids
      |> Enum.each(fn udt_id ->
        %{udt_id: udt_id} |> GodwokenIndexer.Worker.RefreshBridgedUDTSupply.new() |> Oban.insert()
      end)

      script_hash_to_eth_addresses =
        from(a in Account,
          where: a.script_hash in ^account_script_hashes,
          select: {fragment("'0x' || encode(?, 'hex')", a.script_hash), a.eth_address}
        )
        |> Repo.all()
        |> Enum.into(%{})

      udt_id_to_script_hashes =
        from(a in Account,
          where: a.id in ^udt_ids,
          select: {a.id, a.script_hash}
        )
        |> Repo.all()
        |> Enum.into(%{})

      params =
        withdrawal_params
        |> Enum.map(fn %{
                         account_script_hash: account_script_hash,
                         udt_id: udt_id
                       } ->
          address = script_hash_to_eth_addresses[account_script_hash]

          %{
            registry_address: address |> to_string() |> Account.eth_address_to_registry_address(),
            eth_address: address,
            account_id: nil,
            udt_id: udt_id,
            udt_script_hash: udt_id_to_script_hashes[udt_id]
          }
        end)

      {:ok, %GodwokenRPC.Account.FetchedBalances{params_list: import_account_udts}} =
        GodwokenRPC.fetch_balances(params)

      import_account_udts =
        import_account_udts
        |> Enum.map(&Map.put(&1, :block_number, block_number))

      import_account_udts
      |> UpdateSmartContractCKB.update_smart_contract_with_ckb_balance()

      Import.insert_changes_list(
        import_account_udts,
        for: CurrentBridgedUDTBalance,
        timestamps: import_utc_timestamps(),
        on_conflict: {:replace, [:block_number, :value, :updated_at]},
        conflict_target: [:address_hash, :udt_script_hash]
      )
    end
  end

  defp import_polyjuice_creator(polyjuice_creator_params) do
    if polyjuice_creator_params != [] do
      inserted_polyjuice_creator_params =
        filter_polyjuice_creator_columns(polyjuice_creator_params)

      inserted_script_hashes =
        inserted_polyjuice_creator_params
        |> Enum.map(fn creator ->
          account_script = %{
            "code_hash" => creator[:code_hash],
            "hash_type" => creator[:hash_type],
            "args" => creator[:script_args]
          }

          script_to_hash(account_script)
        end)

      Account.batch_import_accounts_with_script_hashes(inserted_script_hashes)

      Import.insert_changes_list(inserted_polyjuice_creator_params,
        for: PolyjuiceCreator,
        timestamps: import_timestamps(),
        on_conflict: :nothing
      )
    end
  end

  defp import_account(transactions_params) do
    account_ids = extract_account_ids(transactions_params)

    exist_ids = from(a in Account, where: a.id in ^account_ids, select: a.id) |> Repo.all()
    not_exist_ids = account_ids -- exist_ids

    if not_exist_ids != [], do: Account.batch_import_accounts_with_ids(not_exist_ids)

    update_from_accounts_nonce(transactions_params)
  end

  defp update_from_accounts_nonce(transactions_params) do
    accounts_and_nonce_attrs =
      transactions_params
      |> Enum.map(fn %{from_account_id: from_account_id, nonce: nonce} ->
        %{id: from_account_id, nonce: nonce + 1} |> Map.merge(import_timestamps())
      end)
      |> Enum.sort_by(&Map.fetch(&1, :nonce), &>=/2)
      |> Enum.uniq_by(&Map.fetch(&1, :id))

    Import.insert_changes_list(accounts_and_nonce_attrs,
      for: Account,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:nonce, :updated_at]},
      conflict_target: :id
    )
  end

  defp update_block_cache([]), do: :ok

  defp update_block_cache(blocks) when is_list(blocks) do
    BlocksCache.update(blocks)
  end

  defp update_transactions_cache(transactions) do
    Transactions.update(transactions)
  end

  defp extract_account_ids(transactions_params) do
    transactions_params
    |> Enum.reduce([], fn transaction, acc ->
      acc ++ transaction[:account_ids]
    end)
    |> Enum.uniq()
  end

  defp filter_transaction_columns(params) do
    params
    |> Enum.map(fn %{
                     hash: hash,
                     eth_hash: eth_hash,
                     from_account_id: from_account_id,
                     to_account_id: to_account_id,
                     args: args,
                     type: type,
                     nonce: nonce,
                     block_number: block_number,
                     block_hash: block_hash,
                     index: index
                   } = param ->
      %{
        hash: hash,
        eth_hash: eth_hash,
        from_account_id: from_account_id,
        to_account_id: to_account_id,
        args: args,
        type: type,
        nonce: nonce,
        block_number: block_number,
        block_hash: block_hash,
        index: index,
        method_id: param[:method_id],
        method_name: param[:method_name]
      }
    end)
  end

  defp filter_polyjuice_columns(params) do
    params
    |> Enum.map(fn %{
                     is_create: is_create,
                     gas_limit: gas_limit,
                     gas_price: gas_price,
                     value: value,
                     input_size: input_size,
                     input: input,
                     gas_used: gas_used,
                     status: status,
                     hash: hash,
                     transaction_index: transaction_index,
                     created_contract_address_hash: created_contract_address_hash,
                     native_transfer_address_hash: native_transfer_address_hash
                   } ->
      %{
        is_create: is_create,
        gas_limit: gas_limit,
        gas_price: gas_price,
        value: value,
        input_size: input_size,
        input: input,
        gas_used: gas_used,
        status: status,
        tx_hash: hash,
        transaction_index: transaction_index,
        created_contract_address_hash: created_contract_address_hash,
        native_transfer_address_hash: native_transfer_address_hash
      }
    end)
  end

  defp filter_polyjuice_creator_columns(params) do
    params
    |> Enum.map(fn %{
                     code_hash: code_hash,
                     hash_type: hash_type,
                     script_args: script_args,
                     fee_amount: fee_amount,
                     fee_registry_id: fee_registry_id,
                     hash: hash
                   } ->
      %{
        code_hash: code_hash,
        hash_type: hash_type,
        script_args: script_args,
        fee_amount: fee_amount,
        fee_registry_id: fee_registry_id,
        tx_hash: hash
      }
    end)
  end

  @spec get_next_block_number :: integer
  defp get_next_block_number do
    case Repo.one(from(block in Block, order_by: [desc: block.number], limit: 1)) do
      %Block{number: number} -> number + 1
      nil -> 0
    end
  end

  defp update_udt_token_instance_metadata(token_transfers) do
    token_transfers =
      Enum.filter(token_transfers, fn tt ->
        if tt.token_type in [:erc721, :erc1155] do
          tt.from_address_hash == GlobalConstants.minted_burned_address()
        else
          false
        end
      end)

    {_without_token_ids, with_token_ids} =
      TokenBalances.params_set(%{token_transfers_params: token_transfers})
      |> Enum.split_with(fn udt_balance -> is_nil(Map.get(udt_balance, :token_id)) end)

    with_token_ids =
      with_token_ids
      |> Enum.map(fn tt ->
        %{
          "token_contract_address_hash" => tt.token_contract_address_hash,
          "token_id" => tt.token_id
        }
      end)

    if length(with_token_ids) > 0 do
      ERC721ERC1155InstanceMetadata.new_job(with_token_ids)
    end
  end

  defp update_udt_balance(token_transfers) do
    {without_token_ids, with_token_ids} =
      TokenBalances.params_set(%{token_transfers_params: token_transfers})
      |> Enum.split_with(fn udt_balance -> is_nil(Map.get(udt_balance, :token_id)) end)

    without_token_ids =
      without_token_ids
      |> Enum.uniq_by(fn map ->
        {map[:address_hash], map[:token_contract_address_hash], map[:block_number],
         map[:token_type]}
      end)
      |> filter_udt_balance_params()

    with_token_ids =
      with_token_ids
      |> Enum.uniq_by(fn map ->
        {map[:address_hash], map[:token_contract_address_hash], map[:block_number],
         map[:token_id], map[:token_type]}
      end)
      |> filter_udt_balance_params()

    Import.insert_changes_list(without_token_ids,
      for: UDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: :nothing,
      conflict_target:
        {:unsafe_fragment,
         ~s<(address_hash, token_contract_address_hash, block_number) WHERE token_id IS NULL>}
    )

    Import.insert_changes_list(with_token_ids,
      for: UDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: :nothing,
      conflict_target:
        {:unsafe_fragment,
         ~s<(address_hash, token_contract_address_hash, token_id, block_number) WHERE token_id IS NOT NULL>}
    )

    :ok
  end

  def filter_udt_balance_params(params_list) do
    params_list
    |> Enum.map(fn %{
                     address_hash: address_hash,
                     token_contract_address_hash: token_contract_address_hash,
                     block_number: block_number,
                     token_id: token_id,
                     token_type: token_type
                   } ->
      %{
        address_hash: address_hash,
        token_contract_address_hash: token_contract_address_hash,
        block_number: block_number,
        token_id: token_id,
        token_type: token_type
      }
    end)
  end

  defp update_ckb_balance(polyjuice_params) do
    with ckb_id when not is_nil(ckb_id) <- UDT.ckb_account_id(),
         %Account{script_hash: ckb_script_hash} = Repo.get(Account, ckb_id) do
      polyjuice_params
      |> Enum.filter(fn %{value: value} -> value > 0 end)
      |> Enum.group_by(&Map.get(&1, :block_number))
      |> Enum.map(fn {block_number, list} ->
        account_ids =
          list
          |> Enum.flat_map(fn %{account_ids: account_ids} ->
            account_ids
          end)
          |> Enum.uniq()

        account_id_to_registry_addresses =
          from(a in Account,
            where: a.id in ^account_ids,
            select: %{
              id: a.id,
              registry_address: a.registry_address,
              eth_address: a.eth_address
            }
          )
          |> Repo.all()

        params =
          account_id_to_registry_addresses
          |> Enum.map(fn account ->
            %{
              registry_address: account.registry_address,
              eth_address: account.eth_address,
              account_id: account.id,
              udt_id: ckb_id,
              udt_script_hash: to_string(ckb_script_hash)
            }
          end)

        {:ok, %GodwokenRPC.Account.FetchedBalances{params_list: import_account_udts}} =
          GodwokenRPC.fetch_balances(params)

        bridged_ckbs =
          import_account_udts
          |> Enum.map(fn ckbs ->
            ckbs |> Map.merge(%{block_number: block_number})
          end)

        bridged_ckbs
        |> UpdateSmartContractCKB.update_smart_contract_with_ckb_balance()

        Import.insert_changes_list(
          bridged_ckbs,
          for: CurrentBridgedUDTBalance,
          timestamps: import_utc_timestamps(),
          on_conflict: {:replace, [:block_number, :value, :updated_at]},
          conflict_target: [:address_hash, :udt_script_hash]
        )
      end)

      {:ok, :import}
    else
      _ -> {:error, :ckb_not_found}
    end
  end

  @spec forked?(GodwokenRPC.hash(), GodwokenRPC.block_number()) :: boolean
  defp forked?(parent_hash, parent_block_number) do
    case Repo.get_by(Block, number: parent_block_number) do
      nil -> false
      %Block{hash: database_hash} -> parent_hash != database_hash
    end
  end

  @spec schedule_work(GodwokenRPC.block_number()) :: reference()
  defp schedule_work(next_block_number) do
    second_interval =
      Application.get_env(:godwoken_explorer, :sync_worker_interval) ||
        @default_worker_interval

    Process.send_after(self(), {:work, next_block_number}, second_interval * 1000)
  end

  defp rpc() do
    Application.get_env(:godwoken_explorer, :rpc_module, GodwokenRPC)
  end
end
