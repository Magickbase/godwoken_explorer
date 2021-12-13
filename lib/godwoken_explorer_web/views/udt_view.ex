defmodule GodwokenExplorer.UDTView do
  use JSONAPI.View, type: "udt"

  import Ecto.Query, only: [from: 2]
  alias GodwokenExplorer.{UDT, Repo, Account, AccountUDT, Transaction}

  def fields do
    [:id, :script_hash, :symbol, :decimal, :name, :supply, :holder_count, :type, :short_address, :type_script, :script_hash, :official_site, :description, :value, :transfer_count, :icon]
  end

  def supply(udt, _conn) do
    if is_nil(udt.supply) do
      ""
    else
      Decimal.to_string(udt.supply)
    end
  end

  def holder_count(udt, _conn) do
    from(
      au in AccountUDT,
      where: au.udt_id == ^udt.id and au.balance > 0
      ) |> Repo.aggregate(:count)
  end

  def transfer_count(udt, _conn) do
    from(t in Transaction, where: t.to_account_id == ^udt.id) |> Repo.aggregate(:count)
  end

  def get_udt(id) do
    from(u in UDT,
      join: a in Account, on: a.id == u.id,
      where: u.id == ^id,
      select: %{id: u.id, short_address: a.short_address, script_hash: u.script_hash, symbol: u.symbol, decimal: u.decimal, name: u.name, supply: u.supply, type: u.type, icon: u.icon}
   ) |> Repo.one()
  end

  def list(type, page) do
    cond do
      type == "bridge" ->
        from(
          u in UDT,
          join: a in Account, on: a.id == u.id,
          where: u.type == :bridge,
          select: %{id: u.id, short_address: a.short_address, script_hash: u.script_hash, symbol: u.symbol, decimal: u.decimal, name: u.name, supply: u.supply, type: u.type, icon: u.icon}
        )
      type == "native" ->
        from(
          u in UDT,
          join: a in Account, on: a.id == u.id,
          where: u.type == :native,
          select: %{id: u.id, short_address: a.short_address, script_hash: u.script_hash, symbol: u.symbol, decimal: u.decimal, name: u.name, supply: u.supply, type: u.type, icon: u.icon}
        )
      true ->
        from(
          u in UDT,
          join: a in Account, on: a.id == u.id,
          select: %{id: u.id, short_address: a.short_address, script_hash: u.script_hash, symbol: u.symbol, decimal: u.decimal, name: u.name, supply: u.supply, type: u.type, icon: u.icon}
        )
    end
    |> Repo.paginate(page: page)
  end
end
