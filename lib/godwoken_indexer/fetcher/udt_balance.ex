defmodule GodwokenIndexer.Fetcher.UDTBalance do
  use GenServer

  import GodwokenRPC.Util,
    only: [
      import_utc_timestamps: 0
    ]

  alias GodwokenExplorer.Chain
  alias GodwokenExplorer.Chain.{Hash, Import}
  alias GodwokenIndexer.Fetcher.UDTBalances
  alias GodwokenExplorer.Account.{CurrentUDTBalance, UDTBalance}

  @default_worker_interval 5

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    # Schedule work to be performed on start
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:import_udt_balance, state) do
    # Do the desired work here
    fetch_and_import()

    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  def fetch_and_import() do
    {:ok, entries} =
      Chain.stream_unfetched_udt_balances([], fn token_balance, acc ->
        [token_balance |> entry() | acc]
      end)

    {:ok, _result} =
      entries
      |> Enum.map(&format_params/1)
      |> fetch_from_blockchain()
      |> import_token_balances()
  end

  def fetch_from_blockchain(params_list) do
    retryable_params_list =
      params_list
      |> Enum.uniq_by(&Map.take(&1, [:token_contract_address_hash, :address_hash, :block_number]))

    {:ok, token_balances} =
      UDTBalances.fetch_token_balances_from_blockchain(retryable_params_list)

    token_balances
  end

  def import_token_balances(token_balances_params) do
    {without_token_ids, with_token_ids} =
      Enum.split_with(token_balances_params, fn tb -> is_nil(Map.get(tb, :token_id)) end)

    {format_without_token_ids, format_with_token_ids} =
      UDTBalances.to_address_current_token_balances(without_token_ids, with_token_ids)

    Import.insert_changes_list(without_token_ids,
      for: UDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: {:replace, [:value, :value_fetched_at, :updated_at]},
      conflict_target:
        {:unsafe_fragment,
         ~s<(address_hash, token_contract_address_hash, block_number) WHERE token_id IS NULL>}
    )

    Import.insert_changes_list(with_token_ids,
      for: UDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: {:replace, [:value, :value_fetched_at, :updated_at]},
      conflict_target:
        {:unsafe_fragment,
         ~s<(address_hash, token_contract_address_hash, token_id, block_number) WHERE token_id IS NOT NULL>}
    )

    Import.insert_changes_list(format_without_token_ids,
      for: CurrentUDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: {:replace, [:value, :value_fetched_at, :updated_at]},
      conflict_target:
        {:unsafe_fragment, ~s<(address_hash, token_contract_address_hash) WHERE token_id IS NULL>}
    )

    Import.insert_changes_list(format_with_token_ids,
      for: CurrentUDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: {:replace, [:value, :value_fetched_at, :updated_at]},
      conflict_target:
        {:unsafe_fragment,
         ~s<(address_hash, token_contract_address_hash, token_id) WHERE token_id IS NOT NULL>}
    )
  end

  defp entry(%{
         token_contract_address_hash: token_contract_address_hash,
         address_hash: address_hash,
         block_number: block_number
       }) do
    {address_hash.bytes, token_contract_address_hash.bytes, block_number}
  end

  defp format_params({address_hash_bytes, token_contract_address_hash_bytes, block_number}) do
    {:ok, token_contract_address_hash} = Hash.Address.cast(token_contract_address_hash_bytes)
    {:ok, address_hash} = Hash.Address.cast(address_hash_bytes)

    %{
      token_contract_address_hash: to_string(token_contract_address_hash),
      address_hash: to_string(address_hash),
      block_number: block_number
    }
  end

  defp schedule_work do
    second =
      Application.get_env(:godwoken_explorer, :udt_balance_fetcher_interval) ||
        @default_worker_interval

    Process.send_after(self(), :import_udt_balance, second * 1000)
  end
end
