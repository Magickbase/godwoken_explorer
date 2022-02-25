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
    case Repo.get_by(__MODULE__, %{account_id: attrs[:account_id], udt_id: attrs[:udt_id]}) do
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
      join: u in UDT,
      on: u.bridge_account_id == a.id,
      where: au.address_hash == ^eth_address,
      select: %{
        id: u.bridge_account_id,
        name: u.name,
        symbol: u.symbol,
        icon: u.icon,
        balance: fragment("CASE WHEN ? IS NOT NULL THEN ? / power(10, ?) ELSE ? END", u.decimal, au.balance, u.decimal, au.balance)
      }
    ) |> Repo.all()
  end

  def sync_balance!(%{script_hash: script_hash, udt_id: udt_id}) do
    with %Account{id: account_id, short_address: short_address} <- Repo.get_by(Account, script_hash: script_hash),
        %Account{short_address: udt_short_address} <- Repo.get(Account, udt_id) do
        {:ok, balance} = GodwokenRPC.fetch_balance(short_address, udt_id)

        AccountUDT.create_or_update_account_udt!(%{
          account_id: account_id,
          address_hash: short_address,
          udt_id: udt_id,
          token_contract_addresss_hash: udt_short_address,
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
          token_contract_addresss_hash: udt_short_address,
          balance: balance
        })
    else
      _ ->
        {:error, :account_not_exist}
    end
  end

end
