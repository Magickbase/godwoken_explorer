defmodule GodwokenExplorer.UDTView do
  use JSONAPI.View, type: "udt"

  import Ecto.Query, only: [from: 2]
  alias GodwokenExplorer.{UDT, Repo, AccountUDT, Transaction}

  def fields do
    [
      :id,
      :script_hash,
      :symbol,
      :decimal,
      :name,
      :supply,
      :holder_count,
      :type,
      :short_address,
      :type_script,
      :script_hash,
      :official_site,
      :description,
      :value,
      :transfer_count,
      :icon
    ]
  end

  def short_address(udt, _conn) do
    udt.account.short_address
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
    )
    |> Repo.aggregate(:count)
  end

  def transfer_count(udt, _conn) do
    from(t in Transaction, where: t.to_account_id == ^udt.id) |> Repo.aggregate(:count)
  end

  def get_udt(id) do
    from(
      u in UDT,
      preload: :account,
      where: u.id == ^id,
      select: map(u, ^select_fields())
    )
    |> Repo.one()
  end

  def list(type, page) do
    cond do
      type == "bridge" ->
        from(
          u in UDT,
          preload: :account,
          where: u.type == :bridge,
          select: map(u, ^select_fields())
        )

      type == "native" ->
        from(
          u in UDT,
          preload: :account,
          where: u.type == :native,
          select: map(u, ^select_fields())
        )

      true ->
        from(
          u in UDT,
          preload: :account,
          select: map(u, ^select_fields())
        )
    end
    |> Repo.paginate(page: page)
  end

  def select_fields do
    udt_fields = [
      :id,
      :script_hash,
      :symbol,
      :decimal,
      :name,
      :supply,
      :type,
      :official_site,
      :description,
      :icon,
      :type_script
    ]

    account_fields = [:short_address]

    udt_fields ++ [account: account_fields]
  end
end
