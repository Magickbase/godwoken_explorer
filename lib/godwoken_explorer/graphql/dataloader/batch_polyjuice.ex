defmodule GodwokenExplorer.Graphql.Dataloader.BatchPolyjuice do
  import Ecto.Query
  alias GodwokenExplorer.Transaction
  alias GodwokenExplorer.Account
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

  def polyjuice_creator_account(Account, script_hashes) do
    from(t in Account)
    |> where(
      [a],
      a.script_hash in ^script_hashes
    )
    |> Repo.all()
    |> Map.new(fn a ->
      {a.script_hash |> to_string(), a}
    end)
  end
end
