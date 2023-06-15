defmodule GodwokenExplorer.Graphql.Resolvers.Transaction do
  import GodwokenExplorer.Graphql.Resolvers.Common,
    only: [paginate_query: 3, query_with_block_age_range: 2]

  import GodwokenExplorer.Graphql.Common, only: [cursor_order_sorter: 3]
  import Ecto.Query
  import GodwokenRPC.Util, only: [script_to_hash: 1]
  import GodwokenIndexer.Block.PendingTransactionWorker, only: [parse_and_import: 1]

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, Transaction, Block, Polyjuice, PolyjuiceCreator}

  import GodwokenExplorer.Graphql.Utils, only: [default_uniq_cursor_order_fields: 3]

  @sorter_fields [:block_number, :index, :hash]
  @default_sorter @sorter_fields
  @account_tx_limit 100_000

  def transaction(_parent, %{input: input} = _args, _resolution) do
    query = query_with_eth_hash_or_tx_hash(input)

    case Repo.one(query) do
      nil ->
        case parse_and_import(input[:eth_hash]) do
          {0, nil} -> {:ok, nil}
          _ -> {:ok, query_with_eth_hash_or_tx_hash(input) |> Repo.one()}
        end

      return ->
        {:ok, return}
    end
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
    |> join(:left, [t], b in Block, as: :block, on: b.hash == t.block_hash)
    |> query_with_status(input)
    |> query_with_account_address(input, from_eth_address, to_eth_address)
    |> query_with_account_address(input, from_script_hash, to_script_hash)
    |> query_with_block_range(input)
    |> query_with_block_age_range(input)
    |> query_with_method_id_name(input)
    |> select([t], %{hash: t.hash, block_number: t.block_number, index: t.index})
    |> transactions_order_by(input)
    |> paginate_query(input, %{
      cursor_fields: paginate_cursor(input),
      total_count_primary_key_field: :hash
    })
    |> do_transactions(input)
  end

  defp do_transactions({:error, {:not_found, []}}, _input), do: {:ok, nil}
  defp do_transactions({:error, _} = error, _input), do: error

  defp do_transactions(
         %Paginator.Page{
           metadata: metadata,
           entries: entries
         },
         input
       ) do
    tx_hashes = entries |> Enum.map(fn entry -> entry.hash end)

    tx_results =
      from(t in Transaction)
      |> where([t], t.hash in ^tx_hashes)
      |> transactions_order_by(input)
      |> Repo.all()

    {:ok,
     %Paginator.Page{
       metadata: metadata,
       entries: tx_results
     }}
  end

  defp query_with_account_address(query, input, from_address, to_address) do
    {from_account, to_account} =
      case {from_address, to_address} do
        {nil, nil} = p ->
          p

        {from_address, nil} ->
          from_account = Account.get_account_by_address(from_address)

          if from_account do
            {from_account, nil}
          else
            {:not_found, nil}
          end

        {nil, to_address} ->
          to_account = Account.get_account_by_address(to_address)

          if to_account do
            {nil, to_account}
          else
            {nil, :not_found}
          end

        {from_address, to_address} ->
          from_account = Account.get_account_by_address(from_address)
          to_account = Account.get_account_by_address(to_address)

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

  defp process_from_to_account(query, input, from_account, to_account) do
    case {from_account, to_account} do
      {:not_found, _} ->
        query
        |> where([t], false)

      {_, :not_found} ->
        query
        |> where([t], false)

      {nil, nil} ->
        query

      {nil, to_account} ->
        query
        |> where([t], t.to_account_id == ^to_account.id)
        |> limit(@account_tx_limit)

      {from_account, nil} ->
        query
        |> where([t], t.from_account_id == ^from_account.id)
        |> limit(@account_tx_limit)

      {from_account, to_account} ->
        if input[:combine_from_to] do
          query |> query_tx_hashes_by_account_type(from_account)
        else
          query
          |> where(
            [t],
            t.to_account_id == ^to_account.id and t.from_account_id == ^from_account.id
          )
        end
        |> limit(@account_tx_limit)
    end
  end

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

  defp query_with_status(query, input) do
    status = Map.get(input, :status)

    cond do
      :pending == status ->
        query
        |> where([t], is_nil(t.block_hash))

      :on_chained == status ->
        query
        |> where([t], not is_nil(t.block_hash))

      true ->
        query
    end
  end

  defp query_with_method_id_name({:error, _} = error, _input), do: error

  defp query_with_method_id_name(query, input) do
    method_id = Map.get(input, :method_id)
    method_name = Map.get(input, :method_name)

    if method_id do
      query
      |> where([t], t.method_id == ^method_id)
    else
      if method_name do
        query
        |> where([t], t.method_name == ^method_name)
      else
        query
      end
    end
  end

  defp transactions_order_by(query, input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      order_params =
        sorter
        |> cursor_order_sorter(:order, @sorter_fields)
        |> default_uniq_cursor_order_fields(:order, [:hash])

      order_by(query, [u], ^order_params)
    else
      order_by(query, [u], @default_sorter)
    end
  end

  defp paginate_cursor(input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      sorter
      |> cursor_order_sorter(:cursor, @sorter_fields)
      |> default_uniq_cursor_order_fields(:cursor, [:hash])
    else
      @default_sorter
    end
  end

  def polyjuice(%Transaction{hash: hash} = tx, _args, _resolution) do
    return =
      from(p in Polyjuice)
      |> where([p], p.tx_hash == ^hash)
      |> Repo.one()

    if return do
      eth_hash = Map.get(tx, :eth_hash)
      result = return |> Map.from_struct() |> Map.put(:eth_hash, eth_hash)
      {:ok, result}
    else
      {:ok, nil}
    end
  end

  def created_account(%PolyjuiceCreator{} = creator, _args, _resolution) do
    account_script = %{
      "code_hash" => creator.code_hash,
      "hash_type" => creator.hash_type,
      "args" => creator.script_args
    }

    l2_script_hash = script_to_hash(account_script)

    {:ok, Repo.get_by(Account, script_hash: l2_script_hash)}
  end

  defp query_tx_hashes_by_account_type(query, account) do
    if account.type == :eth_user do
      query |> where([t], t.from_account_id == ^account.id)

      transaction_query =
        from(t in Transaction,
          select: t.hash,
          where: t.from_account_id == ^account.id
        )

      polyjuice_query =
        from(p in Polyjuice,
          join: t in Transaction,
          on: t.hash == p.tx_hash,
          select: t.hash,
          where: p.native_transfer_address_hash == ^account.eth_address
        )

      query |> where([t], t.hash in subquery(union_all(transaction_query, ^polyjuice_query)))
    else
      query |> where([t], t.to_account_id == ^account.id)
    end
  end
end
