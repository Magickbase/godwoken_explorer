defmodule GodwokenExplorer.Graphql.Dataloader.BatchSmartContract do
  import Ecto.Query

  alias GodwokenExplorer.Account
  alias GodwokenExplorer.Repo

  def account(Account, ids) do
    from(a in Account,
      where: a.id in ^ids
    )
    |> Repo.all()
    |> Map.new(fn a ->
      {a.id, a}
    end)
  end
end
