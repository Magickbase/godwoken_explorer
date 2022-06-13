defmodule GodwokenExplorer.Graphql.Resolvers.Transaction do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, Transaction, Block, Polyjuice, PolyjuiceCreator}

  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query_with_sort_type: 3]

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [sort_type: 3]

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
    from(t in Transaction)
    |> query_with_account_address(input)
    |> query_with_block_range(input)
    |> sort_type(input, [:block_number, :index, :hash])
    |> paginate_query_with_sort_type(input, %{
      cursor_fields: [:block_number, :index, :hash],
      total_count_primary_key_field: :hash
    })
    |> do_transactions()
  end

  defp do_transactions({:error, {:not_found_account, []}}), do: {:ok, nil}
  defp do_transactions({:error, _} = error), do: error

  defp do_transactions(result) do
    {:ok, result}
  end

  defp query_with_account_address(query, input) do
    address = Map.get(input, :address)
    script_hash = Map.get(input, :script_hash)

    account_or_skip =
      case {address, script_hash} do
        {nil, nil} ->
          :skip

        {nil, script_hash} when not is_nil(script_hash) ->
          Account.search(script_hash)

        {address, _} when not is_nil(address) ->
          Account.search(address)
      end

    if account_or_skip == :skip do
      query
    else
      account = account_or_skip

      case account do
        %Account{type: :eth_user} ->
          query
          |> where([t], t.from_account_id == ^account.id)

        %Account{type: type}
        when type in [
               :meta_contract,
               :udt,
               :polyjuice_creator,
               :polyjuice_contract,
               :eth_addr_reg
             ] ->
          query
          |> where([t], t.to_account_id == ^account.id)

        nil ->
          {:error, {:not_found_account, []}}

        error ->
          {:error, "internal error with: #{error}"}
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
