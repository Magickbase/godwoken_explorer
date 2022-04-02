defmodule GodwokenExplorer.Graphql.Resolvers.Block do
  alias GodwokenExplorer.{Block, Account, Transaction}
  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [page_and_size: 2]

  def latest_10_blocks(_parent, _args, _resolution) do
    return =
      from(b in Block)
      |> limit(10)
      |> order_by([b], desc: b.timestamp)
      |> Repo.all()

    {:ok, return}
  end

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
      |> order_by([b], desc: b.timestamp)
      |> Repo.all()

    {:ok, return}
  end

  def account(%Block{aggregator_id: aggregator_id}, _args, _resolution) do
    return = Repo.get(Account, aggregator_id)
    {:ok, return}
  end

  def transactions(%Block{hash: hash}, _args, _resolution) do
    return =
      from(t in Transaction)
      |> where([t], t.block_hash == ^hash)
      |> limit(100)
      |> Repo.all()

    {:ok, return}
  end
end
