defmodule Mix.Tasks.UpdateTxsMethodIdName do
  @moduledoc "Printed when the user requests `mix help update_txs_method_id_name`"

  @shortdoc "running with limit/start/walk args `mix update_txs_method_id_name 350000 0 500` to updating udt balance and current udt balance with token_id/token_type"

  alias GodwokenExplorer.{Transaction, Polyjuice, Account}
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Chain.{Import}

  alias GodwokenExplorer.SmartContract
  alias GodwokenIndexer.Worker.CheckUpdateTransactionMethodIdName, as: CUTMethodIdName

  import Ecto.Query

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

    _cached = SmartContract.cache_abis()
    _cached = SmartContract.account_ids()

    return = iterate_token_transfer(limit_value, start, walk)
    IO.inspect(return)
  end

  def iterate_token_transfer(limit_value, start, walk) do
    if start + walk <= limit_value do
      return = get_transaction_with_base(limit_value, start, walk)
      CUTMethodIdName.batch_update_transaction_method_id_name(return)
      start = start + walk
      iterate_token_transfer(limit_value, start, walk)
    else
      :skip
    end
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

    CUTMethodIdName.common_base_query()
    |> where([t], t.block_number >= ^start and t.block_number < ^unbound_max_range)
    |> Repo.all()
  end
end
