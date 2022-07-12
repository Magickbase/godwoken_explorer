defmodule GodwokenExplorer.UDTView do
  use JSONAPI.View, type: "udt"

  import Ecto.Query, only: [from: 2]
  import GodwokenRPC.Util, only: [balance_to_view: 2]

  alias GodwokenExplorer.{UDT, Repo, Account}
  alias GodwokenExplorer.Account.CurrentUDTBalance

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
      :eth_address,
      :type_script,
      :official_site,
      :description,
      :value,
      :transfer_count,
      :icon
    ]
  end

  def script_hash(udt, _conn) do
    to_string(udt.script_hash)
  end

  def eth_address(udt, _conn) do
    if is_nil(udt.account) do
      ""
    else
      to_string(udt.account.eth_address)
    end
  end

  def supply(udt, _conn) do
    if is_nil(udt.supply) do
      ""
    else
      balance_to_view(udt.supply, udt.decimal || 0)
    end
  end

  def holder_count(udt, _conn) do
    result =
      CurrentUDTBalance.sort_holder_list(
        udt.id,
        %{page: 1, page_size: 1}
      )

    result[:total_count]
  end

  def transfer_count(udt, _conn) do
    if udt.account != nil do
      case Repo.get(Account, udt.bridge_account_id) do
        %Account{token_transfer_count: token_transfer_count} ->
          token_transfer_count

        _ ->
          0
      end
    else
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
          where: u.type == :native and u.eth_type == :erc20,
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

    account_fields = [:eth_address]

    udt_fields ++ [account: account_fields]
  end
end
