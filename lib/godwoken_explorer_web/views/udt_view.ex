defmodule GodwokenExplorer.UDTView do
  use JSONAPI.View, type: "udt"

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{UDT, Repo, Account}
  alias GodwokenExplorer.Account.CurrentUDTBalance

  def fields do
    [
      :id,
      :symbol,
      :decimal,
      :name,
      :supply,
      :holder_count,
      :type,
      :eth_address,
      :official_site,
      :description,
      :transfer_count,
      :icon
    ]
  end

  def eth_address(udt, _conn) do
    to_string(udt.contract_address_hash)
  end

  @spec supply(atom | %{:supply => any, optional(any) => any}, any) :: binary
  def supply(udt, _conn) do
    if is_nil(udt.supply) do
      ""
    else
      udt.supply
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
    cond do
      udt.type == :bridge and udt.bridge_account_id != nil ->
        case Repo.get_by(Account, eth_address: udt.account.eth_address) do
          %Account{token_transfer_count: token_transfer_count} ->
            token_transfer_count

          nil ->
            0
        end

      udt.type == :native and udt.eth_type == :erc20 and udt.contract_address_hash != nil ->
        case Repo.get_by(Account, eth_address: udt.contract_address_hash) do
          %Account{token_transfer_count: token_transfer_count} ->
            token_transfer_count

          nil ->
            0
        end

      true ->
        0
    end
  end

  def get_udt(id) do
    from(
      u in UDT,
      preload: [:account],
      where: u.id == ^id
    )
    |> Repo.one()
  end

  def list(type, page) do
    bridge_account_ids =
      from(u in UDT,
        where: u.type == :bridge and not is_nil(u.bridge_account_id),
        select: u.bridge_account_id
      )
      |> Repo.all()

    cond do
      type == "bridge" ->
        from(u in UDT, where: u.id in ^bridge_account_ids, order_by: [asc: :name])

      type == "native" ->
        from(
          u in UDT,
          where:
            u.type == :native and u.eth_type == :erc20 and u.id not in ^bridge_account_ids and
              not is_nil(u.name),
          order_by: [asc: :name]
        )
    end
    |> Repo.paginate(page: page)
  end
end
