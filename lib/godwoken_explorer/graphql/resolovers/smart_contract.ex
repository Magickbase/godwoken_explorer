defmodule GodwokenExplorer.Graphql.Resolvers.SmartContract do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{SmartContract, Account}

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [cursor_order_sorter: 3]
  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]

  @sorter_fields [:id]
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
          Account.search(script_hash)

        {contract_address, _} when not is_nil(contract_address) ->
          Account.search(contract_address)

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
      from(sc in SmartContract)
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
      order_params = cursor_order_sorter(sorter, :order, @sorter_fields)
      order_by(query, [u], ^order_params)
    else
      order_by(query, [u], @default_sorter)
    end
  end

  defp paginate_cursor(input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      cursor_order_sorter(sorter, :cursor, @sorter_fields)
    else
      @default_sorter
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
