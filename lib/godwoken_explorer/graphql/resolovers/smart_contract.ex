defmodule GodwokenExplorer.Graphql.Resolvers.SmartContract do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{SmartContract, Account}

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [cursor_order_sorter: 3]
  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]

  @sorter_fields [:id, :name]
  # @ex_sorter_fields [:ex_balance, :ex_tx_count]
  @default_sorter [:id]

  def smart_contract(
        _parent,
        %{input: input} = _args,
        _resolution
      ) do
    contract_address = Map.get(input, :contract_address)
    script_hash = Map.get(input, :script_hash)

    account =
      case {contract_address, script_hash} do
        {nil, script_hash} when not is_nil(script_hash) ->
          Repo.get_by(Account, script_hash: script_hash)

        {contract_address, _} when not is_nil(contract_address) ->
          Repo.get_by(Account, eth_address: contract_address)

        {nil, nil} ->
          nil
      end

    if account do
      return =
        from(sc in SmartContract)
        |> where([sc], sc.account_id == ^account.id)
        |> Repo.one()

      {:ok, return}
    else
      {:ok, nil}
    end
  end

  def smart_contracts(_parent, %{input: input} = _args, _resolution) do
    return =
      from(sc in SmartContract, as: :smart_contract)
      |> join(:inner, [sc], a in Account, on: sc.account_id == a.id, as: :account)
      |> smart_contracts_order_by(input)
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: :id
      })

    {:ok, return}
  end

  defp smart_contracts_order_by(query, input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      order_params =
        sorter
        |> Enum.map(fn e ->
          case e do
            %{sort_type: st, sort_value: :ex_tx_count} ->
              {st, dynamic([_s, a], a.transaction_count)}

            _ ->
              case cursor_order_sorter([e], :order, @sorter_fields) do
                [h | _] -> h
                _ -> :skip
              end
          end
        end)
        |> Enum.filter(&(&1 != :skip))

      order_by(query, [], ^order_params)
    else
      order_by(query, [], @default_sorter)
    end
  end

  defp paginate_cursor(input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      sorter
      |> Enum.map(fn e ->
        case e do
          %{sort_type: st, sort_value: :ex_tx_count} ->
            {{:account, :transaction_count}, st}

          _ ->
            case cursor_order_sorter([e], :cursor, @sorter_fields) do
              [h | _] -> h
              _ -> :skip
            end
        end
      end)
      |> Enum.filter(&(&1 != :skip))
    else
      cursor_order_sorter(sorter, :cursor, @sorter_fields)
    end
  end

  def account(%SmartContract{account_id: account_id} = _parent, _args, _resolution) do
    if account_id do
      return = Repo.get(Account, account_id)

      {:ok, return}
    else
      {:ok, nil}
    end
  end
end
