defmodule GodwokenExplorer.Graphql.Resolvers.Transaction do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, Transaction, Block, Polyjuice, PolyjuiceCreator}

  import GodwokenExplorer.Graphql.Resolvers.Common,
    only: [paginate_query: 3, query_with_block_age_range: 2]

  import GodwokenExplorer.Graphql.Common, only: [cursor_order_sorter: 3]
  import Ecto.Query

  @sorter_fields [:block_number, :index, :hash]
  @default_sorter [:block_number, :index, :hash]

  def transaction(_parent, %{input: input} = _args, _resolution) do
    query = query_with_eth_hash_or_tx_hash(input)
    return = Repo.one(query)
    {:ok, return}
  end

  defp query_with_eth_hash_or_tx_hash(input) do
    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:transaction_hash, value} ->
            dynamic([t], ^acc and t.hash == ^value)

          {:eth_hash, value} ->
            dynamic([t], ^acc and t.eth_hash == ^value)

          _ ->
            false
        end
      end)

    from(t in Transaction, where: ^conditions)
  end

  def transactions(_parent, %{input: input} = _args, _resolution) do
    from_eth_address = Map.get(input, :from_eth_address)
    to_eth_address = Map.get(input, :to_eth_address)

    from_script_hash = Map.get(input, :from_script_hash)
    to_script_hash = Map.get(input, :to_script_hash)

    from(t in Transaction)
    |> join(:inner, [t], b in Block, as: :block, on: b.hash == t.block_hash)
    |> query_with_account_address(input, from_eth_address, to_eth_address)
    |> query_with_account_address(input, from_script_hash, to_script_hash)
    |> query_with_block_range(input)
    |> query_with_block_age_range(input)
    |> transactions_order_by(input)
    |> paginate_query(input, %{
      cursor_fields: paginate_cursor(input),
      total_count_primary_key_field: :hash
    })
    |> do_transactions()
  end

  defp do_transactions({:error, {:not_found, []}}), do: {:ok, nil}
  defp do_transactions({:error, _} = error), do: error

  defp do_transactions(result) do
    {:ok, result}
  end

  defp query_with_account_address(query, input, from_address, to_address) do
    {from_account, to_account} =
      case {from_address, to_address} do
        {nil, nil} = p ->
          p

        {from_address, nil} ->
          from_account = Repo.get_by(Account, eth_address: from_address)

          if from_account do
            {from_account, nil}
          else
            {:not_found, nil}
          end

        {nil, to_address} ->
          to_account = Repo.get_by(Account, eth_address: to_address)

          if to_account do
            {nil, to_account}
          else
            {nil, :not_found}
          end

        {from_address, to_address} ->
          from_account = Repo.get_by(Account, eth_address: from_address)
          to_account = Repo.get_by(Account, eth_address: to_address)

          case {from_account, to_account} do
            {nil, nil} ->
              {:not_found, :not_found}

            {nil, _} ->
              {:not_found, to_account}

            {_, nil} ->
              {from_account, :not_found}

            _ ->
              {from_account, to_account}
          end
      end

    query
    |> process_from_to_account(input, from_account, to_account)
  end

  defp process_from_to_account({:error, _} = error, _, _, _), do: error

  defp process_from_to_account(query, input, from_account, to_account) do
    case {from_account, to_account} do
      {:not_found, _} ->
        {:error, :not_found}

      {_, :not_found} ->
        {:error, :not_found}

      {nil, nil} ->
        query

      {nil, to_account} ->
        query
        |> where([t], t.to_account_id == ^to_account.id)

      {from_account, nil} ->
        query
        |> where([t], t.from_account_id == ^from_account.id)

      {from_account, to_account} ->
        if input[:combine_from_to] do
          query
          |> where(
            [t],
            t.to_account_id == ^to_account.id or t.from_account_id == ^from_account.id
          )
        else
          query
          |> where(
            [t],
            t.to_account_id == ^to_account.id and t.from_account_id == ^from_account.id
          )
        end
    end
  end

  defp query_with_block_range({:error, _} = error, _input), do: error

  defp query_with_block_range(query, input) do
    start_block_number = Map.get(input, :start_block_number)
    end_block_number = Map.get(input, :end_block_number)

    query =
      if start_block_number do
        query
        |> where([t], t.block_number >= ^start_block_number)
      else
        query
      end

    if end_block_number do
      query
      |> where([t], t.block_number <= ^end_block_number)
    else
      query
    end
  end

  defp transactions_order_by(query, input) do
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

  def polyjuice(%Transaction{hash: hash}, _args, _resolution) do
    return =
      from(p in Polyjuice)
      |> where([p], p.tx_hash == ^hash)
      |> Repo.one()

    {:ok, return}
  end

  def polyjuice_creator(%Transaction{hash: hash}, _args, _resolution) do
    return =
      from(pc in PolyjuiceCreator)
      |> where([pc], pc.tx_hash == ^hash)
      |> Repo.one()

    {:ok, return}
  end

  def block(%Transaction{block_hash: block_hash}, _args, _resolution) do
    {:ok, Repo.get(Block, block_hash)}
  end

  def from_account(%Transaction{from_account_id: from_account_id}, _args, _resolution) do
    {:ok, Repo.get(Account, from_account_id)}
  end

  def to_account(%Transaction{to_account_id: to_account_id}, _args, _resolution) do
    {:ok, Repo.get(Account, to_account_id)}
  end
end
