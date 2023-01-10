defmodule GodwokenExplorer.Graphql.Dataloader.BatchHistory do
  import Ecto.Query

  alias GodwokenExplorer.UDT
  alias GodwokenExplorer.Repo

  def udt(UDT, udt_ids) do
    from(a in UDT)
    |> where(
      [u],
      u.id in ^udt_ids
    )
    |> Repo.all()
    |> Map.new(fn u ->
      {u.id, u}
    end)
  end
end
