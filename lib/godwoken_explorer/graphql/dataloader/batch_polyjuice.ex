defmodule GodwokenExplorer.Graphql.Dataloader.BatchPolyjuice do
  import Ecto.Query
  alias GodwokenExplorer.Transaction
  alias GodwokenExplorer.Repo

  def eth_hash(Transaction, hash_ids) do
    from(t in Transaction)
    |> where(
      [t],
      t.hash in ^hash_ids
    )
    |> Repo.all()
    |> Map.new(fn t ->
      {t.hash, t.eth_hash}
    end)
  end
end
