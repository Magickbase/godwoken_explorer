defmodule GodwokenExplorer.Graphql.Dataloader.GraphqlEcto do
  def data() do
    Dataloader.Ecto.new(GodwokenExplorer.Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end
end
