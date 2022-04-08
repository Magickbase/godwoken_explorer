defmodule GodwokenExplorer.Graphql.Resolvers.Block do
  alias GodwokenExplorer.{Block, Account, Transaction}
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2]

  def block(_parent, %{input: input} = _args, _resolution) do
    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:hash, value} ->
            dynamic([b], ^acc and b.hash == ^value)

          {:number, value} ->
            dynamic([b], ^acc and b.number == ^value)

          _ ->
            acc
        end
      end)

    return =
      from(b in Block)
      |> where(^conditions)
      |> Repo.one()

    {:ok, return}
  end

  def blocks(_parent, %{input: input} = _args, _resolution) do
    return =
      from(b in Block)
      |> page_and_size(input)
      |> order_by([b], desc: b.number)
      |> Repo.all()

    {:ok, return}
  end

  def account(%Block{aggregator_id: aggregator_id}, _args, _resolution) do
    return = Repo.get(Account, aggregator_id)
    {:ok, return}
  end

  def transactions(%Block{hash: hash}, %{input: input} = _args, _resolution) do
    IO.inspect(input)
    return =
      from(t in Transaction)
      |> where([t], t.block_hash == ^hash)
      |> page_and_size(input)
      |> Repo.all()

    {:ok, return}
  end
end
