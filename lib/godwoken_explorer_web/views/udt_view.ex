defmodule GodwokenExplorer.UDTView do
  use JSONAPI.View, type: "udt"

  import Ecto.Query, only: [from: 2]
  import GodwokenRPC.Util, only: [balance_to_view: 2]

  alias GodwokenExplorer.{UDT, Repo, AccountUDT, Account}

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
      balance_to_view(udt.supply, udt.decimal || 0)
    end
  end

  def holder_count(udt, _conn) do
    token_contract_address_hashes =
      from(a in Account, where: a.id in [^udt.id, ^udt.bridge_account_id], select: a.short_address)
      |> Repo.all()

    from(
      au in AccountUDT,
      where: au.token_contract_address_hash in ^token_contract_address_hashes and au.balance > 0
    )
    |> Repo.aggregate(:count)
  end

  def transfer_count(udt, _conn) do
    case Repo.get(Account, udt.bridge_account_id) do
      %Account{token_transfer_count: token_transfer_count} ->
        token_transfer_count

      _ ->
        0
    end
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
          where: u.type == :bridge and not is_nil(u.bridge_account_id),
          select: map(u, ^select_fields()),
          order_by: [asc: :name]
        )

      type == "native" ->
        from(
          u in UDT,
          preload: :account,
          where: u.type == :native,
          select: map(u, ^select_fields()),
          order_by: [asc: :name]
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
      :type_script,
      :bridge_account_id
    ]

    account_fields = [:short_address]

    udt_fields ++ [account: account_fields]
  end
end
