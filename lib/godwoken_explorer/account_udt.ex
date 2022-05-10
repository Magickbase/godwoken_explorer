defmodule GodwokenExplorer.AccountUDT do
  use GodwokenExplorer, :schema

  require Logger

  alias GodwokenRPC
  alias GodwokenExplorer.Chain.Events.Publisher

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "account_udts" do
    field(:balance, :decimal)
    field(:address_hash, :binary)
    field(:token_contract_address_hash, :binary)
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
      left_join: a1 in Account,
      on: a1.registry_address == au.token_contract_address_hash,
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
        balance:
          fragment(
            "CASE WHEN ? IS NOT NULL THEN trim_scale(? / power(10, ?)::decimal)
          WHEN ? IS NOT NULL THEN trim_scale(? / power(10, ?)::decimal)
          ELSE ? END",
            u3.decimal,
            au.balance,
            u3.decimal,
            u4.decimal,
            au.balance,
            u4.decimal,
            au.balance
          ),
        updated_at: au.updated_at
      }
    )
    |> Repo.all()
    |> unique_account_udts()
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
    with %Account{id: account_id, eth_address: eth_address, registry_address: registry_address} <-
           Repo.get_by(Account, script_hash: script_hash),
         %Account{script_hash: script_hash} <- Repo.get(Account, udt_id) do
      {:ok, balance} = GodwokenRPC.fetch_balance(registry_address, udt_id)

      AccountUDT.create_or_update_account_udt!(%{
        account_id: account_id,
        address_hash: eth_address,
        udt_id: udt_id,
        token_contract_address_hash: script_hash,
        balance: balance
      })
    else
      _ ->
        {:error, :account_not_exist}
    end
  end

  def sync_balance!(%{account_id: account_id, udt_id: udt_id}) do
    with %Account{eth_address: eth_address, registry_address: registry_address} <-
           Repo.get(Account, account_id),
         %Account{script_hash: script_hash} <- Repo.get(Account, udt_id) do
      {:ok, balance} = GodwokenRPC.fetch_balance(registry_address, udt_id)

      AccountUDT.create_or_update_account_udt!(%{
        account_id: account_id,
        address_hash: eth_address,
        udt_id: udt_id,
        token_contract_address_hash: script_hash,
        balance: balance
      })
    else
      _ ->
        {:error, :account_not_exist}
    end
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
