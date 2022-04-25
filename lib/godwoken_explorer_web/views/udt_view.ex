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
      :eth_address,
      :type_script,
      :official_site,
      :description,
      :value,
      :transfer_count,
      :icon
    ]
  end

  def eth_address(udt, _conn) do
    udt.account.eth_address
  end

  def supply(udt, _conn) do
    if is_nil(udt.supply) do
      ""
    else
      balance_to_view(udt.supply, udt.decimal || 0)
    end
  end

  # For udt type account, account_udt token_contract_address_hash is short_address
  # For polyjuice_contract type account, account_udt token_contract_address_hash is eth_address
  def holder_count(udt, _conn) do
    token_contract_address_hashes =
      if udt.type == :bridge do
        %Account{short_address: short_address} = Repo.get(Account, udt.id)

        with %{bridge_account_id: bridge_account_id} when bridge_account_id != nil <- udt,
             %Account{eth_address: eth_address} <- Repo.get(Account, udt.bridge_account_id) do
          [short_address, eth_address]
        else
          _ -> [short_address]
        end
      else
        %Account{eth_address: eth_address} = Repo.get(Account, udt.id)
        [eth_address]
      end

    from(
      au in AccountUDT,
      where: au.token_contract_address_hash in ^token_contract_address_hashes and au.balance > 0,
      distinct: au.address_hash
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
      where: u.id == ^id or u.bridge_account_id == ^id,
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

    account_fields = [:eth_address]

    udt_fields ++ [account: account_fields]
  end
end
