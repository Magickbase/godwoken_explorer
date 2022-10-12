defmodule Mix.Tasks.UpdateTxsMethodIdName do
  @moduledoc "Printed when the user requests `mix help update_txs_method_id_name`"

  @shortdoc "running with limit/start/walk args `mix update_txs_method_id_name 350000 0 500` to updating udt balance and current udt balance with token_id/token_type"

  alias GodwokenExplorer.{Transaction, Polyjuice, Account}
  alias GodwokenExplorer.Repo
  alias GodwokenIndexer.Transform.TokenBalances
  alias GodwokenExplorer.Account.UDTBalance
  alias GodwokenExplorer.Chain.{Import}
  alias GodwokenExplorer.UDT
  import Ecto.Query

  import GodwokenIndexer.Block.SyncWorker, only: [filter_udt_balance_params: 1]

  import GodwokenRPC.Util,
    only: [
      import_timestamps: 0
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
      "mix run update_txs_method_id_name task with args limit/start/walk ===>: #{inspect(args_return)}"
    )

    limit_value = Map.get(args_return, :limit, 500)
    start = Map.get(args_return, :start, 0)
    walk = Map.get(args_return, :walk, 100)

    return = iterate_token_transfer(limit_value, start, walk)
    IO.inspect(return)
  end

  def iterate_token_transfer(limit_value, start, walk) do
    if start + walk <= limit_value do
      return = get_transaction_with_base(limit_value, start, walk)
      do_update_txs_method_id_name(return)
      start = start + walk
      iterate_token_transfer(limit_value, start, walk)
    else
      :skip
    end
  end

  def do_update_txs_method_id_name(txs_with_params) do
    jobs = length(txs_with_params)
    IO.inspect("processing #{jobs} jobs")

    Import.insert_changes_list(txs_with_params,
      for: Transaction,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:method_id, :method_name]},
      conflict_target: :hash
    )
    |> IO.inspect()
  end

  def get_transaction_with_base(limit, start, walk) do
    running_args = %{
      limit: limit,
      start: start,
      walk: walk
    }

    IO.inspect("get_transaction_with_base running args ===>: #{inspect(running_args)}")

    unbound_max_range =
      if walk + start > limit do
        limit
      else
        walk + start
      end

    query =
      from(t in Transaction,
        where: t.block_number >= ^start and t.block_number < ^unbound_max_range,
        inner_join: a in Account,
        on: a.id == t.to_account_id,
        where: a.type == :polyjuice_contract,
        inner_join: p in Polyjuice,
        on: t.hash == p.tx_hash,
        select: %{
          hash: t.hash,
          from_account_id: t.from_account_id,
          to_account_id: t.to_account_id,
          nonce: t.nonce,
          args: t.args,
          input: p.input
        }
      )

    Repo.all(query)
    |> Enum.map(fn map ->
      {method_id, method_name} =
        with input when not is_nil(input) <- map.input,
             input <- input |> to_string(),
             mid <- input |> String.slice(0, 10),
             true <- String.length(mid) >= 10 do
          method_name = Polyjuice.get_method_name(map.to_account_id, input)
          {mid, method_name}
        else
          _ ->
            {"0x00", nil}
        end

      map
      |> Map.delete(:input)
      |> Map.put(:method_id, method_id)
      |> Map.put(:method_name, method_name)
    end)
  end
end
