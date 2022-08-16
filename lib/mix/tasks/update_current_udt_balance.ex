defmodule Mix.Tasks.UpdateCurrentUdtBalance do
  @moduledoc "Printed when the user requests `mix help update_current_udt_balance`"

  @shortdoc "running with limit/start/walk args `mix update_current_udt_balance 500 0 100` to updating udt balance and current udt balance with token_id/token_type"

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Account.UDTBalance
  alias GodwokenExplorer.Account.CurrentUDTBalance

  alias GodwokenIndexer.Fetcher.UDTBalances
  alias GodwokenExplorer.Chain.{Import}

  import Ecto.Query

  import GodwokenRPC.Util,
    only: [
      import_utc_timestamps: 0
    ]

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    args_return =
      case args do
        [limit, start, walk] ->
          %{
            limit: limit |> String.to_integer(),
            start: start |> String.to_integer(),
            walk: walk |> String.to_integer()
          }

        [limit, start] ->
          %{
            limit: limit |> String.to_integer(),
            start: start |> String.to_integer()
          }

        [limit] ->
          %{
            limit: limit |> String.to_integer()
          }

        _ ->
          %{}
      end

    IO.inspect(
      "mix run update_current_udt_balance task with args limit/start/walk ===>: #{inspect(args_return)}"
    )

    limit_value = Map.get(args_return, :limit, 500)
    start = Map.get(args_return, :start, 0)
    walk = Map.get(args_return, :walk, 100)

    return = iterate_do_job(limit_value, start, walk)
    IO.inspect(return)
  end

  def iterate_do_job(limit_value, start, walk) do
    if start + walk <= limit_value do
      return = get_udt_balance_with_base(limit_value, start, walk)
      do_update_current_udt_balance(return)
      start = start + walk
      iterate_do_job(limit_value, start, walk)
    else
      :skip
    end
  end

  def do_update_current_udt_balance(%{
        without_token_ids: without_token_ids,
        with_token_ids: with_token_ids
      }) do
    jobs = length(without_token_ids) + length(with_token_ids)
    IO.inspect("processing #{jobs} jobs")

    {format_without_token_ids, format_with_token_ids} =
      UDTBalances.to_address_current_token_balances(without_token_ids, with_token_ids)

    Import.insert_changes_list(format_without_token_ids,
      for: CurrentUDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: {:replace, [:token_type]},
      conflict_target:
        {:unsafe_fragment, ~s<(address_hash, token_contract_address_hash) WHERE token_id IS NULL>}
    )

    Import.insert_changes_list(format_with_token_ids,
      for: CurrentUDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: {:replace, [:token_id, :token_type]},
      conflict_target:
        {:unsafe_fragment,
         ~s<(address_hash, token_contract_address_hash, token_id) WHERE token_id IS NOT NULL>}
    )
  end

  def get_udt_balance_with_base(limit, start, walk) do
    running_args = %{
      limit: limit,
      start: start,
      walk: walk
    }

    IO.inspect("get_udt_balance_with_base running args ===>: #{inspect(running_args)}")

    unbound_max_range =
      if walk + start > limit do
        limit
      else
        walk + start
      end

    without_token_ids_query =
      from(ub in UDTBalance,
        where:
          ub.block_number >= ^start and ub.block_number < ^unbound_max_range and
            is_nil(ub.token_id) and not is_nil(ub.value_fetched_at),
        order_by: [desc: ub.block_number],
        distinct: [ub.block_number, ub.address_hash, ub.token_contract_address_hash],
        select: %{
          account_id: ub.account_id,
          udt_id: ub.udt_id,
          address_hash: ub.address_hash,
          token_contract_address_hash: ub.token_contract_address_hash,
          value: ub.value,
          value_fetched_at: ub.value_fetched_at,
          block_number: ub.block_number,
          token_id: ub.token_id,
          token_type: ub.token_type
        }
      )

    without_token_ids = Repo.all(without_token_ids_query)

    with_token_ids_query =
      from(ub in UDTBalance,
        where:
          ub.block_number >= ^start and ub.block_number < ^unbound_max_range and
            not is_nil(ub.token_id) and not is_nil(ub.value_fetched_at),
        order_by: [desc: ub.block_number],
        distinct: [ub.block_number, ub.address_hash, ub.token_contract_address_hash],
        select: %{
          account_id: ub.account_id,
          udt_id: ub.udt_id,
          address_hash: ub.address_hash,
          token_contract_address_hash: ub.token_contract_address_hash,
          value: ub.value,
          value_fetched_at: ub.value_fetched_at,
          block_number: ub.block_number,
          token_id: ub.token_id,
          token_type: ub.token_type
        }
      )

    with_token_ids = Repo.all(with_token_ids_query)

    %{without_token_ids: without_token_ids, with_token_ids: with_token_ids}
  end
end
