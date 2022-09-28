defmodule Mix.Tasks.UpdateUdtBalance do
  @moduledoc "Printed when the user requests `mix help update_udt_balance`"

  @shortdoc "running with limit/start/walk args `mix update_udt_balance 350000 0 500` to updating udt balance and current udt balance with token_id/token_type"

  alias GodwokenExplorer.TokenTransfer
  alias GodwokenExplorer.Repo
  alias GodwokenIndexer.Transform.TokenBalances
  alias GodwokenExplorer.Account.UDTBalance
  alias GodwokenExplorer.Chain.{Import}
  alias GodwokenExplorer.UDT
  import Ecto.Query

  import GodwokenIndexer.Block.SyncWorker, only: [filter_udt_balance_params: 1]

  import GodwokenRPC.Util,
    only: [
      import_utc_timestamps: 0
    ]

  use Mix.Task

  require Logger

  # @chunk_size 100

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
      "mix run update_udt_balance task with args limit/start/walk ===>: #{inspect(args_return)}"
    )

    limit_value = Map.get(args_return, :limit, 500)
    start = Map.get(args_return, :start, 0)
    walk = Map.get(args_return, :walk, 100)

    return = iterate_token_transfer(limit_value, start, walk)
    IO.inspect(return)
  end

  def iterate_token_transfer(limit_value, start, walk) do
    if start + walk <= limit_value do
      return = get_token_transfer_with_base(limit_value, start, walk)
      do_update_udt_balance(return)
      start = start + walk
      iterate_token_transfer(limit_value, start, walk)
    else
      :skip
    end
  end

  def do_update_udt_balance(token_transfers) do
    {without_token_ids, with_token_ids} =
      TokenBalances.params_set(%{token_transfers_params: token_transfers})
      |> Enum.split_with(fn udt_balance -> is_nil(Map.get(udt_balance, :token_id)) end)

    jobs = length(without_token_ids) + length(with_token_ids)
    IO.inspect("processing #{jobs} jobs")

    with_token_ids =
      with_token_ids
      |> Enum.uniq_by(fn map ->
        {map[:address_hash], map[:token_contract_address_hash], map[:block_number],
         map[:token_id], map[:token_type]}
      end)
      |> filter_udt_balance_params()

    without_token_ids =
      without_token_ids
      |> Enum.uniq_by(fn map ->
        {map[:address_hash], map[:token_contract_address_hash], map[:block_number],
         map[:token_type]}
      end)
      |> filter_udt_balance_params()

    # default_conflict = GodwokenIndexer.Fetcher.UDTBalance.default_token_balance_on_conflict()

    Import.insert_changes_list(without_token_ids,
      for: UDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: {:replace, [:token_type]},
      # on_conflict: default_conflict,
      conflict_target:
        {:unsafe_fragment,
         ~s<(address_hash, token_contract_address_hash, block_number) WHERE token_id IS NULL>}
    )

    Import.insert_changes_list(with_token_ids,
      for: UDTBalance,
      timestamps: import_utc_timestamps(),
      on_conflict: {:replace, [:token_id, :token_type]},
      # on_conflict: default_conflict,
      conflict_target:
        {:unsafe_fragment,
         ~s<(address_hash, token_contract_address_hash, token_id, block_number) WHERE token_id IS NOT NULL>}
    )
  end

  def get_token_transfer_with_base(limit, start, walk) do
    running_args = %{
      limit: limit,
      start: start,
      walk: walk
    }

    IO.inspect("get_token_transfer_with_base running args ===>: #{inspect(running_args)}")

    unbound_max_range =
      if walk + start > limit do
        limit
      else
        walk + start
      end

    query =
      from(tt in TokenTransfer,
        where: tt.block_number >= ^start and tt.block_number < ^unbound_max_range,
        inner_join: u in UDT,
        on: u.contract_address_hash == tt.token_contract_address_hash,
        select: %{
          block_number: tt.block_number,
          token_id: tt.token_id,
          token_type: u.eth_type,
          token_contract_address_hash: tt.token_contract_address_hash,
          from_address_hash: tt.from_address_hash,
          to_address_hash: tt.to_address_hash,
          token_ids: tt.token_ids
        }
      )

    Repo.all(query)
    |> Enum.map(fn map ->
      token_type =
        if map[:token_type] do
          map[:token_type]
        else
          # raise "query udt type error with: #{inspect(map.token_contract_address_hash |> to_string)}"
          if map[:token_ids] do
            :erc1155
          else
            if map[:token_id] do
              Logger.error(fn -> "cannot confirm token transfer's eth type" end)
              # :erc721 or erc1155
              raise "query udt type error with: #{inspect(map.token_contract_address_hash |> to_string)}"
            else
              :erc20
            end
          end
        end

      %{
        block_number: map[:block_number],
        token_id: map[:token_id],
        token_ids: map[:token_ids],
        token_type: token_type,
        token_contract_address_hash: map[:token_contract_address_hash] |> to_string,
        from_address_hash: map[:from_address_hash] |> to_string,
        to_address_hash: map[:to_address_hash] |> to_string
      }
    end)
  end
end
