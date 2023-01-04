defmodule GodwokenExplorer.Graphql.Resolvers.History do
  alias GodwokenExplorer.{WithdrawalHistory, DepositHistory}
  alias GodwokenExplorer.UDT
  alias GodwokenExplorer.Account
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Graphql.Dataloader.BatchHistory

  import GodwokenExplorer.Graphql.Common, only: [cursor_order_sorter: 3]
  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]
  import Ecto.Query
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  @default_sorter [:timestamp, :layer1_tx_hash, :layer1_output_index]

  def deposit_withdrawal_histories(_parent, %{input: input} = _args, _resolution) do
    q =
      do_deposit_withdrawal_histories(input)
      |> dw_histories_order_by(input)

    q =
      from(u in UDT,
        right_join: sq in subquery(q),
        as: :sq,
        on: u.id == sq.udt_id,
        select: sq
      )

    q
    |> paginate_query(input, %{
      cursor_fields: paginate_cursor(input),
      total_count_primary_key_field: @default_sorter
    })
    |> do_result()
  end

  defp do_result({:error, {:not_found, []}}), do: {:ok, nil}
  defp do_result({:error, _} = error), do: error

  defp do_result(result) do
    {:ok, result}
  end

  defp dw_histories_order_by(query, input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      order_params =
        sorter
        |> cursor_order_sorter(:order, [:timestamp])

      order_params = order_params ++ [:layer1_tx_hash, :layer1_output_index]
      order_by(query, [u], ^order_params)
    else
      order_by(query, [u], @default_sorter)
    end
  end

  defp paginate_cursor(input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      sorter =
        sorter
        |> Enum.map(fn e ->
          case e do
            %{sort_type: st, sort_value: :timestamp} ->
              {{:sq, :timestamp}, st}

            _ ->
              cursor_order_sorter(e, :cursor, @default_sorter)
          end
        end)

      sorter ++ [{{:sq, :layer1_tx_hash}, :asc}, {{:sq, :layer1_output_index}, :asc}]
    else
      @default_sorter
    end
  end

  defp do_deposit_withdrawal_histories(input) do
    condition =
      Enum.reduce(input, true, fn {k, v}, acc ->
        case {k, v} do
          {:udt_id, udt_id} when is_integer(udt_id) ->
            udt_id =
              case UDT |> Repo.get(udt_id) do
                %UDT{id: id, type: :bridge} ->
                  id

                %UDT{id: id, type: :native} ->
                  case Repo.get_by(UDT, bridge_account_id: id) do
                    %UDT{id: id} -> id
                    nil -> nil
                  end

                nil ->
                  nil
              end

            if is_nil(udt_id) do
              dynamic([b], ^acc and false)
            else
              dynamic([b], ^acc and b.udt_id == ^udt_id)
            end

          {:eth_address, eth_address} when not is_nil(eth_address) ->
            dynamic([account: ac], ^acc and ac.eth_address == ^eth_address)

          _ ->
            dynamic([b], ^acc)
        end
      end)

    history_with_block_number(condition, input)
  end

  defp history_with_block_number(condition, input) do
    if not is_nil(input[:start_block_number]) or not is_nil(input[:end_block_number]) do
      condition =
        Enum.reduce(input, condition, fn {k, v}, acc ->
          case {k, v} do
            {:start_block_number, value} ->
              dynamic([b], ^acc and b.block_number >= ^value)

            {:end_block_number, value} ->
              dynamic([b], ^acc and b.block_number <= ^value)

            _ ->
              dynamic([b], ^acc)
          end
        end)

      withdrawal_base_query(condition)
    else
      deposits = deposit_base_query(condition)
      withdrawals = withdrawal_base_query(condition)

      from(q in subquery(deposits |> union_all(^withdrawals)))
    end
  end

  def udt(%{udt_id: udt_id}, _args, _resolution) do
    batch({BatchHistory, :udt, UDT}, udt_id, fn batch_results ->
      {:ok, Map.get(batch_results, udt_id)}
    end)
  end

  defp withdrawal_base_query(condition) do
    from(w in WithdrawalHistory,
      join: u in UDT,
      on: u.id == w.udt_id,
      join: a2 in Account,
      as: :account,
      on: a2.script_hash == w.l2_script_hash,
      where: ^condition,
      select: %{
        script_hash: w.l2_script_hash,
        eth_address: a2.eth_address,
        value: w.amount,
        owner_lock_hash: w.owner_lock_hash,
        sudt_script_hash: w.udt_script_hash,
        udt_id: w.udt_id,
        udt_name: u.name,
        udt_symbol: u.symbol,
        udt_icon: u.icon,
        udt_decimal: u.decimal,
        block_hash: w.block_hash,
        block_number: w.block_number,
        timestamp: w.timestamp,
        layer1_block_number: w.layer1_block_number,
        layer1_tx_hash: w.layer1_tx_hash,
        layer1_output_index: w.layer1_output_index,
        ckb_lock_hash: nil,
        state: w.state,
        capacity: w.capacity,
        type: "withdrawal"
      }
    )
  end

  defp deposit_base_query(condition) do
    from(d in DepositHistory,
      join: u in UDT,
      on: u.id == d.udt_id,
      join: a2 in Account,
      as: :account,
      on: a2.script_hash == d.script_hash,
      where: ^condition,
      select: %{
        script_hash: d.script_hash,
        eth_address: a2.eth_address,
        value: d.amount,
        owner_lock_hash: nil,
        sudt_script_hash: nil,
        udt_id: d.udt_id,
        udt_name: u.name,
        udt_symbol: u.symbol,
        udt_icon: u.icon,
        udt_decimal: u.decimal,
        block_hash: nil,
        block_number: nil,
        timestamp: d.timestamp,
        layer1_block_number: d.layer1_block_number,
        layer1_tx_hash: d.layer1_tx_hash,
        layer1_output_index: d.layer1_output_index,
        ckb_lock_hash: d.ckb_lock_hash,
        state: "succeed",
        capacity: d.capacity,
        type: "deposit"
      }
    )
  end
end
