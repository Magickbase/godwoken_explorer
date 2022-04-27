defmodule GodwokenIndexer.Block.SyncWorker do
  use GenServer

  import GodwokenRPC.Util, only: [import_timestamps: 0]
  import Ecto.Query, only: [from: 2]

  require Logger

  alias GodwokenIndexer.Worker.ImportContractCode
  alias GodwokenExplorer.Token.BalanceReader
  alias GodwokenIndexer.Transform.{TokenTransfers, TokenBalances}
  alias GodwokenRPC.{Blocks, Receipts}

  alias GodwokenExplorer.{
    AccountUDT,
    Block,
    Transaction,
    Chain,
    Repo,
    Account,
    WithdrawalRequest,
    Log,
    TokenTransfer,
    Polyjuice,
    PolyjuiceCreator,
    UDT
  }

  alias GodwokenExplorer.Chain.Events.Publisher
  alias GodwokenExplorer.Chain.Cache.Blocks, as: BlocksCache
  alias GodwokenExplorer.Chain.Cache.Transactions

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
     }} = GodwokenRPC.fetch_blocks_by_range(range)

    if is_nil(multiple_block_once?) do
      {:ok, _} = validate_last_block_fork(blocks_params, next_block_number)
    end

    {:ok, inserted_transactions} =
      if transactions_params_without_receipts != [] do
        import_account(transactions_params_without_receipts)

        {polyjuice_without_receipts, polyjuice_creator_params, _eth_addr_reg_params,
         _unknown_params} = group_transaction_params(transactions_params_without_receipts)

        handle_polyjuice_transactions(polyjuice_without_receipts)

        import_polyjuice_creator(polyjuice_creator_params)

        inserted_transactions =
          import_transactions(blocks_params, transactions_params_without_receipts)

        update_transactions_cache(inserted_transactions)
        {:ok, inserted_transactions}
      else
        {:ok, []}
      end

    import_withdrawal_requests(withdrawal_params)
    inserted_blocks = import_block(blocks_params)
    update_block_cache(inserted_blocks)

    broadcast_block_and_tx(inserted_blocks, inserted_transactions)

    if multiple_block_once? do
      {:ok, next_block_number + block_batch_size + 1}
    else
      {:ok, next_block_number + 1}
    end
  end

  defp handle_polyjuice_transactions(polyjuice_without_receipts) do
    if polyjuice_without_receipts != [] do
      {polyjuice_transaction, polyjuice_deploy_contract} =
        polyjuice_without_receipts |> Enum.split_while(fn polyjuice -> polyjuice[:eth_hash] end)

      polyjuice_deploy_contract =
        polyjuice_deploy_contract
        |> Enum.map(fn x ->
          x
          |> Map.merge(%{
            gas_used: 0,
            status: :succeed,
            transaction_index: nil,
            created_contract_address_hash: nil
          })
        end)

      {:ok, %{logs: logs, receipts: receipts}} =
        GodwokenRPC.fetch_transaction_receipts(polyjuice_transaction)

      polyjuice_with_receipts = Receipts.put(polyjuice_transaction, receipts)
      import_logs(logs)
      import_token_transfers(logs)
      import_polyjuice(polyjuice_with_receipts ++ polyjuice_deploy_contract)
      update_ckb_balance(polyjuice_without_receipts)
      async_contract_code(polyjuice_with_receipts)
    end
  end

  defp async_contract_code(polyjuice_with_receipts) do
    polyjuice_with_receipts
    |> Enum.filter(fn attrs -> attrs[:created_contract_address_hash] != nil end)
    |> Enum.each(fn attrs ->
      %{block_number: attrs[:block_number], address: attrs[:created_contract_address_hash]}
      |> ImportContractCode.new()
      |> Oban.insert()
    end)
  end

  defp group_transaction_params(transactions_params_without_receipts) do
    grouped = transactions_params_without_receipts |> Enum.group_by(fn tx -> tx[:type] end)

    {grouped[:polyjuice] || [], grouped[:polyjuice_creator] || [],
     grouped[:eth_address_registry] || [], grouped[:unknown] || []}
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
      Repo.insert_all(
        Block,
        blocks_params |> Enum.map(fn block -> Map.merge(block, import_timestamps()) end),
        on_conflict: :nothing,
        returning: [:hash, :number, :transaction_count, :size, :timestamp]
      )

    returned_values
  end

  defp import_logs(logs) do
    import_all_batch(Log, logs)
  end

  defp import_all_batch(module, changesets) do
    reducer = fn {changeset, index}, multi ->
      Ecto.Multi.insert_all(multi, "insert_all#{index}", module, changeset, on_conflict: :nothing)
    end

    changesets
    |> Enum.map(fn changeset -> Map.merge(changeset, import_timestamps()) end)
    |> Enum.chunk_every(5_000)
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), reducer)
    |> Repo.transaction()
  end

  defp import_token_transfers(logs) do
    %{token_transfers: token_transfers, tokens: _tokens} = TokenTransfers.parse(logs)

    import_all_batch(TokenTransfer, token_transfers)

    if length(token_transfers) > 0, do: update_erc20_balance(token_transfers)
  end

  defp import_transactions(block_params, transactions_params_without_receipts) do
    inserted_transaction_params = filter_transaction_columns(transactions_params_without_receipts)

    {_count, returned_values} =
      Repo.insert_all(Transaction, inserted_transaction_params,
        on_conflict: :nothing,
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

  defp import_polyjuice(polyjuice_with_receipts) do
    inserted_polyjuice_params = filter_polyjuice_columns(polyjuice_with_receipts)
    import_all_batch(Polyjuice, inserted_polyjuice_params)
  end

  defp import_withdrawal_requests(withdrawal_params) do
    if withdrawal_params != [] do
      Repo.insert_all(WithdrawalRequest, withdrawal_params, on_conflict: :nothing)

      withdrawal_params
      |> Enum.each(fn %{account_script_hash: account_script_hash, udt_id: udt_id} ->
        AccountUDT.sync_balance!(%{script_hash: account_script_hash, udt_id: udt_id})
      end)
    end
  end

  defp import_polyjuice_creator(polyjuice_creator_params) do
    if polyjuice_creator_params != [] do
      inserted_polyjuice_creator_params =
        filter_polyjuice_creator_columns(polyjuice_creator_params)

      Repo.insert_all(PolyjuiceCreator, inserted_polyjuice_creator_params, on_conflict: :nothing)
    end
  end

  defp broadcast_block_and_tx(inserted_blocks, inserted_transactions) do
    home_blocks =
      Enum.map(inserted_blocks, fn block ->
        Map.take(block, [:hash, :number, :timestamp, :transaction_count])
      end)

    home_transactions =
      Enum.map(inserted_transactions, fn tx ->
        tx
        |> Map.take([:hash, :type, :from, :to, :to_alias])
        |> Map.merge(%{
          timestamp: home_blocks |> List.first() |> Map.get(:timestamp)
        })
      end)

    data = Chain.home_api_data(home_blocks, home_transactions)
    Publisher.broadcast([{:home, data}], :realtime)

    Enum.each(data[:tx_list], fn tx ->
      result = %{
        page: "1",
        total_count: "1",
        txs: [Map.merge(tx, %{block_number: home_blocks |> List.first() |> Map.get(:number)})]
      }

      Publisher.broadcast([{:account_transactions, result}], :realtime)
    end)
  end

  defp import_account(transactions_params) do
    account_ids = extract_account_ids(transactions_params)

    exist_ids = from(a in Account, where: a.id in ^account_ids, select: a.id) |> Repo.all()
    not_exist_ids = account_ids -- exist_ids

    if not_exist_ids != [], do: Account.batch_import_accounts(not_exist_ids)

    update_from_accounts_nonce(transactions_params)
  end

  defp update_from_accounts_nonce(transactions_params) do
    accounts_and_nonce_attrs =
      transactions_params
      |> Enum.map(fn %{from_account_id: from_account_id, nonce: nonce} ->
        %{id: from_account_id, nonce: nonce} |> Map.merge(import_timestamps())
      end)
      |> Enum.sort_by(&Map.fetch(&1, :nonce), &>=/2)
      |> Enum.uniq_by(&Map.fetch(&1, :id))

    Repo.insert_all(Account, accounts_and_nonce_attrs,
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
                   } ->
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
        index: index
      }
      |> Map.merge(import_timestamps())
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
                     created_contract_address_hash: created_contract_address_hash
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
        created_contract_address_hash: created_contract_address_hash
      }
      |> Map.merge(import_timestamps())
    end)
  end

  defp filter_polyjuice_creator_columns(params) do
    params
    |> Enum.map(fn %{
                     code_hash: code_hash,
                     hash_type: hash_type,
                     script_args: script_args,
                     fee_amount: fee_amount,
                     hash: hash
                   } ->
      %{
        code_hash: code_hash,
        hash_type: hash_type,
        script_args: script_args,
        fee_amount: fee_amount,
        tx_hash: hash
      }
      |> Map.merge(import_timestamps())
    end)
  end

  @spec get_next_block_number :: integer
  defp get_next_block_number do
    case Repo.one(from(block in Block, order_by: [desc: block.number], limit: 1)) do
      %Block{number: number} -> number + 1
      nil -> 0
    end
  end

  defp update_erc20_balance(token_transfers) do
    address_token_balances =
      TokenBalances.params_set(%{token_transfers_params: token_transfers})
      |> Enum.uniq_by(fn map -> {map[:address_hash], map[:token_contract_address_hash]} end)

    balances = BalanceReader.get_balances_of(address_token_balances)

    import_account_udts =
      address_token_balances
      |> Enum.with_index()
      |> Enum.map(fn {%{
                        address_hash: address_hash,
                        token_contract_address_hash: token_contract_address_hash
                      }, index} ->
        with {:ok, balance} <- balances |> Enum.at(index) do
          %{
            address_hash: address_hash,
            token_contract_address_hash: token_contract_address_hash,
            balance: balance
          }
          |> Map.merge(import_timestamps())
        else
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    Repo.insert_all(AccountUDT, import_account_udts,
      on_conflict: {:replace, [:balance, :updated_at]},
      conflict_target: [:address_hash, :token_contract_address_hash]
    )

    :ok
  end

  defp update_ckb_balance(polyjuice_params) do
    nil

    if length(polyjuice_params) > 0 do
      ckb_id = UDT.ckb_account_id()
      nil

      if not is_nil(ckb_id) do
        nil

        %Account{short_address: ckb_contract_address} = Repo.get(Account, ckb_id)

        account_ids =
          polyjuice_params
          |> Enum.filter(fn %{value: value} -> value > 0 end)
          |> Enum.flat_map(fn %{account_ids: account_ids} ->
            account_ids
          end)
          |> Enum.uniq()

        account_id_to_short_addresses =
          from(a in Account,
            where: a.id in ^account_ids,
            select: %{id: a.id, short_address: a.short_address, eth_address: a.eth_address}
          )
          |> Repo.all()

        params =
          account_id_to_short_addresses
          |> Enum.reject(&is_nil(Map.fetch!(&1, :eth_address)))
          |> Enum.map(fn account ->
            %{
              short_address: account.short_address,
              eth_address: account.eth_address,
              account_id: account.id,
              udt_id: ckb_id,
              token_contract_address_hash: ckb_contract_address
            }
          end)

        nil

        {:ok, %GodwokenRPC.Account.FetchedBalances{params_list: import_account_udts}} =
          GodwokenRPC.fetch_balances(params)

        nil

        import_account_udts =
          import_account_udts
          |> Enum.map(fn import_au -> import_au |> Map.merge(import_timestamps()) end)

        nil

        Repo.insert_all(AccountUDT, import_account_udts,
          on_conflict: {:replace, [:balance, :updated_at]},
          conflict_target: [:address_hash, :token_contract_address_hash]
        )
      end
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
end
