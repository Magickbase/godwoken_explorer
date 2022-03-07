defmodule GodwokenExplorer.Graphql.Resolvers.Block do
  alias GodwokenExplorer.{Block}

  # TODO: add latest 10 blocks
  def latest_10_blocks(_parent, _args, _resolution) do
    {:ok, Block.latest_10_records()}
  end

  # TODO: find block by hash
  def block(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: list block by page
  def blocks(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: get account by block
  def account(%Block{}, _args, _resolution) do
    {:ok, nil}
  end
end
