defmodule GodwokenExplorer.Graphql.Dataloader.BatchAccount do
  import Ecto.Query
  alias GodwokenExplorer.UDT
  alias GodwokenExplorer.Repo

  def udt(UDT, ids) do
    ids = ids |> Enum.uniq()

    u_u2s =
      from(u in UDT)
      |> where([u], u.id in ^ids)
      |> join(:left, [u], u2 in UDT, on: u.bridge_account_id == u2.id)
      |> select([u, u2], %{u: u, u2: u2})
      |> Repo.all()

    u_u2s
    |> Enum.map(fn u_u2 ->
      if u_u2[:u2] do
        {u_u2[:u].id, u_u2[:u2]}
      else
        {u_u2[:u].id, u_u2[:u]}
      end
    end)
    |> Map.new()
  end

  def bridge_udt(UDT, ids) do
    from(u in UDT)
    |> where(
      [u],
      u.id in ^ids and u.type == :bridge
    )
    |> Repo.all()
    |> Map.new(fn u ->
      {u.id, u}
    end)
  end
end
