defmodule GodwokenExplorer.AccountUDT do
  use GodwokenExplorer, :schema

  require Logger

  alias GodwokenRPC
  alias GodwokenExplorer.Chain.Events.Publisher

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "account_udts" do
    field :balance, :decimal
    field :address_hash, :binary
    field :token_contract_address_hash, :binary
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
    case Repo.get_by(__MODULE__, %{address_hash: attrs[:address_hash], token_contract_address_hash: attrs[:token_contract_address_hash]}) do
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

  def list_udt_by_account_id(account_id) do
    reserve_account_ids = Enum.reject([UDT.ckb_account_id()] ++ [UDT.eth_account_id()], &is_nil/1)

    conditions = dynamic([au, u], au.account_id == ^account_id)

    conditions =
      if length(reserve_account_ids) == 0 do
        conditions
      else
        dynamic([au, u], u.id not in ^reserve_account_ids and ^conditions)
      end

    from(au in AccountUDT,
      join: u in UDT,
      on: [id: au.udt_id],
      where: ^conditions,
      select: %{name: u.name, icon: u.icon, balance: au.balance, decimal: u.decimal}
    )
    |> Repo.all()
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
        name: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u1, u2.name, u1.name),
        symbol: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u1, u2.symbol, u1.symbol),
        icon: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", u1, u2.icon, u1.icon),
        balance:
        fragment(
          "CASE WHEN ? IS NOT NULL THEN ? / power(10, ?)::decimal
          WHEN ? IS NOT NULL THEN ? / power(10, ?)::decimal
          ELSE ? END",
          u1.decimal,
          au.balance,
          u1.decimal,
          u2.decimal,
          au.balance,
          u2.decimal,
          au.balance
        ),
        updated_at: au.updated_at
      }
    )
    |> Repo.all()
    |> unique_account_udts()
  end

  def unique_account_udts(results) do
    results |> Enum.group_by(fn result -> result[:id] end) |> Enum.reduce([], fn {id, account_udts}, acc ->
      if not(is_nil(id)) and id != UDT.ckb_account_id do
        if length(account_udts) > 1 do
          latest_au = account_udts |> Enum.sort_by(fn au -> au[:updated_at] end) |> List.last
          [latest_au | acc ]
        else
          [List.first(account_udts) | acc]
        end
      else
        acc
      end
    end)
  end

  def sync_balance!(%{script_hash: script_hash, udt_id: udt_id}) do
    with %Account{id: account_id, short_address: short_address} <- Repo.get_by(Account, script_hash: script_hash),
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

end
