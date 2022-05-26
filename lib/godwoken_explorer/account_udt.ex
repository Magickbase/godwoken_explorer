defmodule GodwokenExplorer.AccountUDT do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [balance_to_view: 2]

  require Logger

  alias GodwokenRPC
  alias GodwokenExplorer.Chain.Events.Publisher
  alias GodwokenExplorer.Chain
  alias GodwokenExplorer.Chain.Hash

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "account_udts" do
    field :balance, :decimal
    field :address_hash, Hash.Address
    field :token_contract_address_hash, Hash.Address
    belongs_to(:account, GodwokenExplorer.Account, foreign_key: :account_id, references: :id)
    belongs_to(:udt, GodwokenExplorer.UDT, foreign_key: :udt_id, references: :id)

    timestamps()
  end

  @doc false
  def changeset(account_udt, attrs) do
    account_udt
    |> cast(attrs, [:account_id, :udt_id, :balance, :address_hash, :token_contract_address_hash])
    |> validate_required([:address_hash, :token_contract_address_hash])
    |> unique_constraint([:address_hash, :token_contract_address_hash],
      name: :account_udts_address_hash_token_contract_address_hash_index
    )
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
      join: a in Account,
      on: a.short_address == au.token_contract_address_hash,
      left_join: u1 in UDT,
      on: u1.bridge_account_id == a.id,
      left_join: u2 in UDT,
      on: u2.id == a.id,
      where: au.address_hash == ^eth_address and au.balance != 0,
      select: %{
        id: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u1, u2.id, u1.id),
        type: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u1, u2.type, u1.type),
        name: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u1, u2.name, u1.name),
        symbol: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u1, u2.symbol, u1.symbol),
        icon: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u1, u2.icon, u1.icon),
        balance: au.balance,
        udt_decimal:
          fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u1, u2.decimal, u1.decimal),
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

  def sync_balance!(%{script_hash: _script_hash, udt_id: nil}), do: {:error, :udt_not_exists}
  def sync_balance!(%{account_id: _account_id, udt_id: nil}), do: {:error, :udt_not_exists}

  def sync_balance!(%{script_hash: script_hash, udt_id: udt_id}) do
    with %Account{id: account_id, short_address: short_address} <-
           Repo.get_by(Account, script_hash: script_hash),
         %Account{short_address: udt_short_address} <- Repo.get(Account, udt_id) do
      {:ok, balance} = GodwokenRPC.fetch_balance(short_address, udt_id)

      AccountUDT.create_or_update_account_udt!(%{
        account_id: account_id,
        address_hash: short_address,
        udt_id: udt_id,
        token_contract_address_hash: udt_short_address,
        balance: balance
      })
    else
      _ ->
        {:error, :account_not_exist}
    end
  end

  def sync_balance!(%{account_id: account_id, udt_id: udt_id}) do
    with %Account{short_address: short_address} <- Repo.get(Account, account_id),
         %Account{short_address: udt_short_address} <- Repo.get(Account, udt_id) do
      {:ok, balance} = GodwokenRPC.fetch_balance(short_address, udt_id)

      AccountUDT.create_or_update_account_udt!(%{
        account_id: account_id,
        address_hash: short_address,
        udt_id: udt_id,
        token_contract_address_hash: udt_short_address,
        balance: balance
      })
    else
      _ ->
        {:error, :account_not_exist}
    end
  end

  def get_ckb_balance(hashes) do
    hashes_and_short_addresses = Chain.hashes_to_addresses(hashes)

    addresses =
      hashes_and_short_addresses
      |> Enum.map(fn hash_and_short_address -> hash_and_short_address[:short_address] end)

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

    hashes_and_short_addresses
    |> Enum.map(fn hash_and_short_address ->
      result =
        results
        |> Enum.find(fn result -> result[:address] == hash_and_short_address[:short_address] end)

      if is_nil(result) do
        %{
          account: hash_and_short_address[:hash],
          balance: 0
        }
      else
        %{
          account: hash_and_short_address[:hash],
          balance: result[:balance]
        }
      end
    end)
  end

  def sort_holder_list(udt_id, paging_options) do
    case Repo.get(UDT, udt_id) do
      %UDT{type: :native, supply: supply, decimal: decimal} ->
        %Account{short_address: short_address} = Repo.get(Account, udt_id)

        address_and_balances =
          from(au in AccountUDT,
            join: a1 in Account,
            on: a1.short_address == au.address_hash,
            where: au.token_contract_address_hash == ^short_address and au.balance > 0,
            select: %{
              eth_address: fragment("CASE WHEN ? = 'user' THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END", a1.type, a1.eth_address, a1.short_address),
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

      %UDT{type: :bridge, bridge_account_id: bridge_account_id, supply: supply, decimal: decimal} ->
        udt_short_addresses =
          from(a in Account, select: a.short_address, where: a.id in [^udt_id, ^bridge_account_id])
          |> Repo.all()

        sub_query =
          from(au in AccountUDT,
            join: a1 in Account,
            on: a1.short_address == au.address_hash,
            where: au.token_contract_address_hash in ^udt_short_addresses and au.balance > 0,
            select: %{
              eth_address: fragment("CASE WHEN ? = 'user' THEN encode(?, 'escape')
        ELSE encode(?, 'escape') END", a1.type, a1.eth_address, a1.short_address),
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
