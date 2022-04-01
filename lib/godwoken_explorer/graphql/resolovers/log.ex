defmodule GodwokenExplorer.Graphql.Resolvers.Log do
  alias GodwokenExplorer.Log
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2]

  def logs(_parent, %{input: input} = _args, _resolution) do
    return =
      query_logs(input)
      |> Repo.all()

    {:ok, return}
  end

  defp query_logs(input) do
    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
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
    |> page_and_size(input)
  end
end
