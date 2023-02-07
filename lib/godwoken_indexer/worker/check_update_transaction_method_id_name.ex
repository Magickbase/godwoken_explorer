defmodule GodwokenIndexer.Worker.CheckUpdateTransactionMethodIdName do
  use Oban.Worker, queue: :default, max_attempts: 3

  import Ecto.Query

  import GodwokenRPC.Util,
    only: [
      import_timestamps: 0
    ]

  alias GodwokenExplorer.Chain.{Import}
  alias GodwokenExplorer.{Repo, Account, Transaction, SmartContract, Polyjuice}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    do_perform()
  end

  def do_perform() do
    return1 = common_base_query() |> process_order_by_limit() |> Repo.all()
    batch_update_transaction_method_id_name(return1)

    # check method name if smart_contract abi update later
    return2 =
      check_method_name_query()
      |> process_order_by_limit()
      |> Repo.all()

    batch_update_transaction_method_id_name(return2)
    {:ok, nil}
  end

  def batch_update_transaction_method_id_name(return) do
    IO.inspect(length(return), label: "need update transaction count ===>")
    concurrency = 500

    result =
      return
      |> Enum.chunk_every(concurrency)
      |> Enum.reduce(0, fn maps, acc ->
        return =
          maps
          |> Task.async_stream(
            fn map ->
              {method_id, method_name} =
                with input when not is_nil(input) <- map.input,
                     input <- input |> to_string(),
                     mid <- input |> String.slice(0, 10),
                     true <- String.length(mid) >= 10 do
                  method_name =
                    Polyjuice.get_method_name_without_account_check(
                      map.to_account_id,
                      input |> to_string
                    )

                  {mid, method_name}
                else
                  _ ->
                    {nil, nil}
                end

              map
              |> Map.delete(:input)
              |> Map.put(:method_id, method_id)
              |> Map.put(:method_name, method_name)
            end,
            timeout: :infinity
          )
          |> Enum.map(fn {:ok, r} -> r end)
          |> Enum.filter(fn r -> not is_nil(r.method_id) end)

        Import.insert_changes_list(return,
          for: Transaction,
          timestamps: import_timestamps(),
          on_conflict: {:replace, [:method_id, :method_name]},
          conflict_target: :hash
        )

        IO.inspect(acc + length(return), label: "data was processed ==>")
      end)

    {:ok, result}
  end

  def common_base_query() do
    common_query()
    |> where([transaction: t], is_nil(t.method_id))
  end

  defp common_query() do
    from(t in Transaction,
      as: :transaction,
      inner_join: sc in SmartContract,
      on: t.to_account_id == sc.account_id,
      as: :smart_contract,
      inner_join: a in Account,
      as: :account,
      on: a.id == t.to_account_id,
      where: a.type == :polyjuice_contract,
      inner_join: p in Polyjuice,
      as: :polyjuice,
      on: t.hash == p.tx_hash,
      where: p.input_size >= 10,
      select: %{
        hash: t.hash,
        from_account_id: t.from_account_id,
        to_account_id: t.to_account_id,
        nonce: t.nonce,
        args: t.args,
        input: p.input
      }
    )
  end

  def check_method_name_query() do
    common_query()
    |> where([transaction: t], not is_nil(t.method_id) and is_nil(t.method_name))
    |> where(
      [smart_contract: sc],
      not is_nil(sc.abi)
    )
  end

  def process_order_by_limit(query) do
    query
    |> order_by([transaction: t], desc: t.updated_at)
    |> limit(1000)
  end
end
