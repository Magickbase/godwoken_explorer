defmodule GodwokenExplorer.Graphql.Resolvers.Transaction do
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.{Account, Transaction, Block, Polyjuice, PolyjuiceCreator}

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2, sort_type: 3]

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
    |> page_and_size(input)
    |> sort_type(input, [:block_number, :index])
    |> do_transactions
  end

  defp do_transactions({:error, _} = error), do: error

  defp do_transactions(query) do
    {:ok, Repo.all(query)}
  end

  defp query_with_account_address(query, input) do
    address = Map.get(input, :address)

    if is_nil(address) do
      query
    else
      account = Account.search(address)

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
          {:error, "address not found"}
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
