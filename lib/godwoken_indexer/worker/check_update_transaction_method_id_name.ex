defmodule GodwokenIndexer.Worker.CheckUpdateTransactionMethodIdName do
  use Oban.Worker, queue: :default, max_attempts: 3

  import Ecto.Query, only: [from: 2, order_by: 3, limit: 2, where: 3]

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
    return = common_base_query() |> process_where_order_by_limit() |> Repo.all()
    txs_with_params = pre_process_params(return)

    result =
      txs_with_params
      |> Enum.chunk_every(1000)
      |> Enum.reduce(0, fn chunk_list, acc ->
        Import.insert_changes_list(chunk_list,
          for: Transaction,
          timestamps: import_timestamps(),
          on_conflict: {:replace, [:method_id, :method_name]},
          conflict_target: :hash
        )

        (acc + length(chunk_list)) |> IO.inspect(label: "import finished ===>")
      end)

    {:ok, result}
  end

  def pre_process_params(return) do
    IO.inspect(length(return), label: "need update transaction count ===>: ")
    concurrency = 500

    {return_lst, _} =
      return
      |> Enum.chunk_every(concurrency)
      |> Enum.reduce({[], 0}, fn maps, {acc, cacc} ->
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
                    Polyjuice.get_method_name_without_account_check(map.to_account_id, input)

                  {mid, method_name}
                else
                  _ ->
                    {"0x00", nil}
                end

              map
              |> Map.delete(:input)
              |> Map.put(:method_id, method_id)
              |> Map.put(:method_name, method_name)
            end,
            timeout: :infinity
          )
          |> Enum.map(fn {:ok, r} -> r end)

        IO.inspect(cacc + length(return), label: "data pre processed ==>")
        {[return | acc], cacc + length(return)}
      end)

    return_lst
    |> Enum.reverse()
    |> List.flatten()
  end

  def common_base_query() do
    from(t in Transaction,
      inner_join: sc in SmartContract,
      on: t.to_account_id == sc.account_id,
      as: :smart_contract,
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
  end

  def process_where_order_by_limit(query) do
    query
    |> where([t], is_nil(t.method_id))
    |> order_by([smart_contract: sc], desc: sc.updated_at)
    |> limit(1000)
  end
end
