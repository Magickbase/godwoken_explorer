defmodule GodwokenExplorer.Account.CurrentUDTBalance do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [balance_to_view: 2]

  require Logger

  alias GodwokenRPC
  alias GodwokenExplorer.Chain.Events.Publisher
  alias GodwokenExplorer.Chain.Hash

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "account_current_udt_balances" do
    field :value, :decimal
    field(:value_fetched_at, :utc_datetime_usec)
    field(:block_number, :integer)
    field :address_hash, Hash.Address
    field :token_contract_address_hash, Hash.Address
    belongs_to(:account, GodwokenExplorer.Account, foreign_key: :account_id, references: :id)
    belongs_to(:udt, GodwokenExplorer.UDT, foreign_key: :udt_id, references: :id)

    timestamps()
  end

  @doc false
  def changeset(account_udt, attrs) do
    account_udt
    |> cast(attrs, [
      :account_id,
      :udt_id,
      :address_hash,
      :token_contract_address_hash,
      :value,
      :value_fetched_at,
      :block_number
    ])
    |> validate_required([:address_hash, :token_contract_address_hash])
    |> unique_constraint([:address_hash, :token_contract_address_hash])
  end

  def create_or_update_account_udt!(attrs) do
    case Repo.get_by(__MODULE__, %{
           address_hash: attrs[:address_hash],
           token_contract_address_hash: attrs[:token_contract_address_hash]
         }) do
      nil -> %__MODULE__{}
      account_udt -> account_udt
    end
    |> changeset(attrs)
    |> Repo.insert_or_update!()
    |> case do
      account_udt = %AccountUDT{} ->
        account_api_data =
          account_udt.account_id |> Account.find_by_id() |> Account.account_to_view()

        Publisher.broadcast([{:accounts, account_api_data}], :realtime)
        {:ok, account_udt}

      {:error, _} ->
        {:error, nil}
    end
  end

  def list_udt_by_eth_address(eth_address) do
    from(au in AccountUDT,
      left_join: a1 in Account,
      on: a1.id == au.udt_id,
      left_join: a2 in Account,
      on: a2.eth_address == au.token_contract_address_hash,
      left_join: u3 in UDT,
      on: u3.id == a1.id,
      left_join: u4 in UDT,
      on: u4.bridge_account_id == a2.id,
      where: au.address_hash == ^eth_address and au.balance != 0,
      select: %{
        id: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u3, u4.id, u3.id),
        type: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u3, u4.type, u3.type),
        name: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u3, u4.name, u3.name),
        symbol: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u3, u4.symbol, u3.symbol),
        icon: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u3, u4.icon, u3.icon),
        balance: au.balance,
        udt_decimal:
          fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u3, u4.decimal, u3.decimal),
        updated_at: au.updated_at
      }
    )
    |> Repo.all()
    |> unique_account_udts()
    |> Enum.map(fn record ->
      record
      |> Map.merge(%{balance: balance_to_view(record[:balance], record[:udt_decimal] || 0)})
    end)
  end

  def unique_account_udts(results) do
    results
    |> Enum.group_by(fn result -> result[:id] end)
    |> Enum.reduce([], fn {id, account_udts}, acc ->
      if not is_nil(id) and id != UDT.ckb_account_id() do
        if length(account_udts) > 1 do
          latest_au = account_udts |> Enum.sort_by(fn au -> au[:updated_at] end) |> List.last()
          [latest_au | acc]
        else
          [List.first(account_udts) | acc]
        end
      else
        acc
      end
    end)
  end

  def get_ckb_balance(addresses) do
    udt_addresses = UDT.ckb_account_id() |> UDT.get_bridge_and_natvie_address()

    results =
      from(au in AccountUDT,
        where: au.address_hash in ^addresses and au.token_contract_address_hash in ^udt_addresses,
        select: %{
          address: au.address_hash,
          balance: au.balance,
          updated_at: au.updated_at
        }
      )
      |> Repo.all()
      |> Enum.group_by(fn result -> result[:address] end)
      |> Enum.reduce([], fn {_address, account_udts}, acc ->
        if length(account_udts) > 1 do
          latest_au = account_udts |> Enum.sort_by(fn au -> au[:updated_at] end) |> List.last()
          [latest_au | acc]
        else
          [List.first(account_udts) | acc]
        end
      end)

    addresses
    |> Enum.map(fn address ->
      result =
        results
        |> Enum.find(fn result -> result[:address] == address end)

      if is_nil(result) do
        %{
          account: address,
          balance: 0
        }
      else
        %{
          account: address,
          balance: result[:balance]
        }
      end
    end)
  end

  def sort_holder_list(udt_id, paging_options) do
    case Repo.get(UDT, udt_id) do
      %UDT{type: :native, supply: supply, decimal: decimal} ->
        token_contract_address_hashes = UDT.list_address_by_udt_id(udt_id)

        address_and_balances =
          from(au in AccountUDT,
            join: a1 in Account,
            on: a1.eth_address == au.address_hash,
            where:
              au.token_contract_address_hash in ^token_contract_address_hashes and au.balance > 0,
            select: %{
              eth_address: a1.eth_address,
              balance: au.balance,
              tx_count:
                fragment(
                  "CASE WHEN ? is null THEN 0 ELSE ? END",
                  a1.transaction_count,
                  a1.transaction_count
                )
            },
            order_by: [desc: au.balance]
          )
          |> Repo.paginate(page: paging_options[:page], page_size: paging_options[:page_size])

        parse_holder_sort_results(address_and_balances, supply, decimal || 0)

      %UDT{type: :bridge, supply: supply, decimal: decimal} ->
        token_contract_address_hashes = UDT.list_address_by_udt_id(udt_id)

        sub_query =
          from(au in AccountUDT,
            join: a1 in Account,
            on: a1.eth_address == au.address_hash,
            where:
              au.token_contract_address_hash in ^token_contract_address_hashes and au.balance > 0,
            select: %{
              eth_address: a1.eth_address,
              balance: au.balance,
              tx_count:
                fragment(
                  "CASE WHEN ? is null THEN 0 ELSE ? END",
                  a1.transaction_count,
                  a1.transaction_count
                )
            },
            distinct: au.address_hash,
            order_by: [desc: au.updated_at]
          )

        address_and_balances =
          from(sq in subquery(sub_query), order_by: [desc: sq.balance])
          |> Repo.paginate(page: paging_options[:page], page_size: paging_options[:page_size])

        parse_holder_sort_results(address_and_balances, supply, decimal || 0)
    end
  end

  defp parse_holder_sort_results(address_and_balances, supply, decimal) do
    results =
      address_and_balances.entries
      |> Enum.map(fn %{balance: balance} = result ->
        percentage =
          if is_nil(supply) do
            0.0
          else
            D.div(balance, supply) |> D.mult(D.new(100)) |> D.round(2) |> D.to_string()
          end

        result
        |> Map.merge(%{
          percentage: percentage,
          balance: D.div(balance, Integer.pow(10, decimal))
        })
      end)

    %{
      page: address_and_balances.page_number,
      total_count: address_and_balances.total_entries,
      results: results
    }
  end
end
