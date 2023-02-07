defmodule Mix.Tasks.UpdatePolyjuiceGasLessInfo do
  @moduledoc "Printed when the user requests `mix help update_polyjuice_gas_less_info`"

  @shortdoc "running with limit/start/walk args `mix update_polyjuice_gas_less_info 350000 0 500` to updating udt balance and current udt balance with token_id/token_type"

  alias GodwokenExplorer.Repo

  alias GodwokenExplorer.Transaction
  alias GodwokenExplorer.Polyjuice
  alias GodwokenExplorer.Chain.{Import}

  import Ecto.Query

  import GodwokenRPC.Util,
    only: [import_timestamps: 0, parse_polyjuice_args: 1, parse_gas_less_data: 1]

  use Mix.Task

  require Logger

  @gas_less_entrypoint_id Application.compile_env(:godwoken_explorer, :gas_less_entrypoint_id)

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
      "mix run UpdatePolyjuiceGasLessInfo task with args limit/start/walk ===>: #{inspect(args_return)}"
    )

    limit_value = Map.get(args_return, :limit, 500)
    start = Map.get(args_return, :start, 0)
    walk = Map.get(args_return, :walk, 100)

    return = iterate(limit_value, start, walk)
    IO.inspect(return)
  end

  def iterate(limit_value, start, walk) do
    if start + walk <= limit_value do
      return = get_transaction_with_base(limit_value, start, walk)
      do_update_polyjuice_gas_less_info(return)
      start = start + walk
      iterate(limit_value, start, walk)
    else
      :skip
    end
  end

  def do_update_polyjuice_gas_less_info(transactions) do
    need_update_polyjuices_info =
      transactions
      |> Enum.map(fn transaction ->
        args = transaction.args |> to_string()
        "0x" <> args = args
        to_account_id = transaction.to_account_id

        [
          _is_create,
          _gas_limit,
          gas_price,
          _value,
          _input_size,
          input,
          _native_transfer_address_hash
        ] = parse_polyjuice_args(args)

        {call_contract, call_data, call_gas_limit, verification_gas_limit, max_fee_per_gas,
         max_priority_fee_per_gas,
         paymaster_and_data} =
          if to_account_id == @gas_less_entrypoint_id && gas_price == 0 &&
               String.starts_with?(input, "0xfb4350d8") do
            input |> String.slice(10..-1) |> parse_gas_less_data()
          else
            {nil, nil, nil, nil, nil, nil, nil}
          end

        %{
          tx_hash: transaction.tx_hash,
          call_contract: call_contract,
          call_data: call_data,
          call_gas_limit: call_gas_limit,
          verification_gas_limit: verification_gas_limit,
          max_fee_per_gas: max_fee_per_gas,
          max_priority_fee_per_gas: max_priority_fee_per_gas,
          paymaster_and_data: paymaster_and_data
        }
      end)

    Import.insert_changes_list(need_update_polyjuices_info,
      for: Polyjuice,
      timestamps: import_timestamps(),
      conflict_target: :tx_hash,
      on_conflict:
        {:replace,
         [
           :call_contract,
           :call_data,
           :call_gas_limit,
           :verification_gas_limit,
           :max_fee_per_gas,
           :max_priority_fee_per_gas,
           :paymaster_and_data,
           :updated_at
         ]}
    )
  end

  def update_all_polyjuice_gas_less_info() do
    need_update_polyjuices_info =
      from(p in Polyjuice,
        where: is_nil(p.call_contract) and not is_nil(p.gas_price) and p.gas_price == 0,
        inner_join: t in Transaction,
        on: t.hash == p.tx_hash,
        where: t.to_account_id == ^@gas_less_entrypoint_id
      )
      |> Repo.all()
      |> Enum.map(fn p ->
        input = p.input |> to_string()

        {call_contract, call_data, call_gas_limit, verification_gas_limit, max_fee_per_gas,
         max_priority_fee_per_gas,
         paymaster_and_data} =
          if String.starts_with?(input, "0xfb4350d8") do
            input |> String.slice(10..-1) |> parse_gas_less_data()
          else
            {nil, nil, nil, nil, nil, nil, nil}
          end

        gas_less_info = %{
          call_contract: call_contract,
          call_data: call_data,
          call_gas_limit: call_gas_limit,
          verification_gas_limit: verification_gas_limit,
          max_fee_per_gas: max_fee_per_gas,
          max_priority_fee_per_gas: max_priority_fee_per_gas,
          paymaster_and_data: paymaster_and_data
        }

        p
        |> Map.from_struct()
        |> Map.merge(gas_less_info)
      end)

    Import.insert_changes_list(need_update_polyjuices_info,
      for: Polyjuice,
      timestamps: import_timestamps(),
      conflict_target: :tx_hash,
      on_conflict:
        {:replace,
         [
           :call_contract,
           :call_data,
           :call_gas_limit,
           :verification_gas_limit,
           :max_fee_per_gas,
           :max_priority_fee_per_gas,
           :paymaster_and_data,
           :updated_at
         ]}
    )
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

    gas_less_entrypoint_id = @gas_less_entrypoint_id

    from(t in Transaction,
      where: t.block_number >= ^start and t.block_number < ^unbound_max_range,
      where: t.type == :polyjuice and t.to_account_id == ^gas_less_entrypoint_id
    )
    |> Repo.all()
  end
end
