defmodule GodwokenExplorer.Graphql.Resolvers.Log do
  alias GodwokenExplorer.Log
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.UDT

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [cursor_order_sorter: 3]
  import GodwokenExplorer.Graphql.Utils, only: [default_uniq_cursor_order_fields: 3]

  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]

  @sorter_fields [:block_number, :transaction_hash, :index]
  @default_sorter @sorter_fields

  def logs(_parent, %{input: input} = _args, _resolution) do
    input
    |> query_logs()
    |> logs_order_by(input)
    |> paginate_query(input, %{
      cursor_fields: paginate_cursor(input),
      total_count_primary_key_field: [:transaction_hash, :index]
    })
    |> do_logs()
  end

  def udt(%Log{address_hash: address_hash}, _, _resolution) do
    return = Repo.get_by(UDT, contract_address_hash: address_hash)
    {:ok, return}
  end

  defp query_logs(input) do
    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:transaction_hash, value} ->
            dynamic([l], ^acc and l.transaction_hash == ^value)

          {:first_topic, value} ->
            dynamic([l], ^acc and l.first_topic == ^value)

          {:second_topic, value} ->
            dynamic([l], ^acc and l.second_topic == ^value)

          {:third_topic, value} ->
            dynamic([l], ^acc and l.third_topic == ^value)

          {:address_hash, value} ->
            dynamic([l], ^acc and l.address_hash == ^value)

          {:start_block_number, value} ->
            dynamic([l], ^acc and l.block_number >= ^value)

          {:end_block_number, value} ->
            dynamic([l], ^acc and l.block_number <= ^value)

          _ ->
            acc
        end
      end)

    from(l in Log, where: ^conditions)
  end

  defp do_logs({:error, {:not_found, []}}), do: {:ok, nil}
  defp do_logs({:error, _} = error), do: error

  defp do_logs(result) do
    {:ok, result}
  end

  defp logs_order_by(query, input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      order_params =
        sorter
        |> cursor_order_sorter(:order, @sorter_fields)
        |> default_uniq_cursor_order_fields(:order, [:transaction_hash, :index])

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
end
