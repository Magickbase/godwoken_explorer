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

  import Ecto.Query

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

    {{:ok, _}, {:ok, _}, {:ok, _}, {:ok, _}} =
      entries
      |> Enum.map(&format_params/1)
      |> fetch_from_blockchain()
      |> import_token_balances()
  end

  def fetch_from_blockchain(params_list) do
    retryable_params_list =
      params_list
      |> Enum.uniq_by(
        &Map.take(&1, [
          :token_contract_address_hash,
          :address_hash,
          :block_number,
          :token_id,
          :token_type
        ])
      )

    {:ok, token_balances} =
      UDTBalances.fetch_token_balances_from_blockchain(retryable_params_list)

    token_balances
  end

  def import_token_balances(token_balances_params) do
    {without_token_ids, with_token_ids} =
      Enum.split_with(token_balances_params, fn tb -> is_nil(Map.get(tb, :token_id)) end)

    {format_without_token_ids, format_with_token_ids} =
      UDTBalances.to_address_current_token_balances(without_token_ids, with_token_ids)

    ub_default_conflict = default_token_balance_on_conflict()

    return1 =
      Import.insert_changes_list(without_token_ids,
        for: UDTBalance,
        timestamps: import_utc_timestamps(),
        on_conflict: ub_default_conflict,
        conflict_target:
          {:unsafe_fragment,
           ~s<(address_hash, token_contract_address_hash, block_number) WHERE token_id IS NULL>}
      )

    return2 =
      Import.insert_changes_list(with_token_ids,
        for: UDTBalance,
        timestamps: import_utc_timestamps(),
        on_conflict: ub_default_conflict,
        conflict_target:
          {:unsafe_fragment,
           ~s<(address_hash, token_contract_address_hash, token_id, block_number) WHERE token_id IS NOT NULL>}
      )

    cub_default_conflict = default_current_token_balance_on_conflict()

    return3 =
      Import.insert_changes_list(format_without_token_ids,
        for: CurrentUDTBalance,
        timestamps: import_utc_timestamps(),
        # on_conflict: {:replace, [:value, :value_fetched_at, :updated_at]},
        on_conflict: cub_default_conflict,
        conflict_target:
          {:unsafe_fragment,
           ~s<(address_hash, token_contract_address_hash) WHERE token_id IS NULL>}
      )

    return4 =
      Import.insert_changes_list(format_with_token_ids,
        for: CurrentUDTBalance,
        timestamps: import_utc_timestamps(),
        # on_conflict: {:replace, [:value, :value_fetched_at, :updated_at]},
        on_conflict: cub_default_conflict,
        conflict_target:
          {:unsafe_fragment,
           ~s<(address_hash, token_contract_address_hash, token_id) WHERE token_id IS NOT NULL>}
      )

    {return1, return2, return3, return4}
  end

  def default_token_balance_on_conflict do
    from(
      ub in UDTBalance,
      update: [
        set: [
          value: fragment("EXCLUDED.value"),
          value_fetched_at: fragment("EXCLUDED.value_fetched_at"),
          token_type: fragment("EXCLUDED.token_type"),
          token_id: fragment("EXCLUDED.token_id"),
          inserted_at: fragment("LEAST(EXCLUDED.inserted_at, ?)", ub.inserted_at),
          updated_at: fragment("GREATEST(EXCLUDED.updated_at, ?)", ub.updated_at)
        ]
      ],
      where:
        fragment("EXCLUDED.value IS NOT NULL") and
          (is_nil(ub.value_fetched_at) or
             fragment("? < EXCLUDED.value_fetched_at", ub.value_fetched_at))
    )
  end

  def default_current_token_balance_on_conflict do
    from(
      cub in CurrentUDTBalance,
      update: [
        set: [
          block_number: fragment("EXCLUDED.block_number"),
          value: fragment("EXCLUDED.value"),
          value_fetched_at: fragment("EXCLUDED.value_fetched_at"),
          token_id: fragment("EXCLUDED.token_id"),
          token_type: fragment("EXCLUDED.token_type"),
          inserted_at: fragment("LEAST(EXCLUDED.inserted_at, ?)", cub.inserted_at),
          updated_at: fragment("GREATEST(EXCLUDED.updated_at, ?)", cub.updated_at)
        ]
      ],
      where:
        fragment("? < EXCLUDED.block_number", cub.block_number) or
          (fragment("EXCLUDED.value IS NOT NULL") and
             is_nil(cub.value_fetched_at) and
             fragment("? = EXCLUDED.block_number", cub.block_number))
    )
  end

  defp entry(%{
         token_contract_address_hash: token_contract_address_hash,
         address_hash: address_hash,
         block_number: block_number,
         token_id: token_id,
         token_type: token_type
       }) do
    token_id_int =
      case token_id do
        %Decimal{} -> Decimal.to_integer(token_id)
        id_int when is_integer(id_int) -> id_int
        _ -> token_id
      end

    %{
      token_contract_address_hash_bytes: token_contract_address_hash.bytes,
      address_hash_bytes: address_hash.bytes,
      block_number: block_number,
      token_id: token_id_int,
      token_type: token_type
    }
  end

  defp format_params(%{
         token_contract_address_hash_bytes: token_contract_address_hash_bytes,
         address_hash_bytes: address_hash_bytes,
         block_number: block_number,
         token_id: token_id,
         token_type: token_type
       }) do
    {:ok, token_contract_address_hash} = Hash.Address.cast(token_contract_address_hash_bytes)
    {:ok, address_hash} = Hash.Address.cast(address_hash_bytes)

    %{
      token_contract_address_hash: to_string(token_contract_address_hash),
      address_hash: to_string(address_hash),
      block_number: block_number,
      token_id: token_id,
      token_type: token_type
    }
  end

  defp schedule_work do
    second =
      Application.get_env(:godwoken_explorer, :udt_balance_fetcher_interval) ||
        @default_worker_interval

    Process.send_after(self(), :import_udt_balance, second * 1000)
  end
end
