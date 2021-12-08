defmodule GodwokenExplorer.UDTView do
  use JSONAPI.View, type: "udt"

  import Ecto.Query, only: [from: 2]
  alias GodwokenExplorer.{UDT, Repo, Account, AccountUDT}

  def fields do
    [:id, :script_hash, :symbol, :decimal, :name, :supply, :holder_count, :type, :short_address, :type_script, :script_hash, :official_site, :description, :value, :transfer_count]
  end

  def holder_count(udt, _conn) do
    from(
      au in AccountUDT,
      where: au.udt_id == ^udt.id and au.balance > 0
      ) |> Repo.aggregate(:count)
  end

  def transfer_count(udt, _conn) do
    0
  end

  def list(page) do
    from(
      u in UDT,
      join: a in Account, on: a.id == u.id,
      select: %{id: u.id, short_address: a.short_address, script_hash: u.script_hash, symbol: u.symbol, decimal: u.decimal, name: u.name, supply: u.supply, type: u.type}
    ) |> Repo.paginate(page: page)
  end
end
