defmodule GodwokenExplorer.AccountUDT do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [hex_to_number: 1]

  require Logger

  alias GodwokenRPC
  alias GodwokenExplorer.Chain.Events.Publisher

  schema "account_udts" do
    field :balance, :decimal
    belongs_to(:account, GodwokenExplorer.Account, foreign_key: :account_id, references: :id)
    belongs_to(:udt, GodwokenExplorer.UDT, foreign_key: :udt_id, references: :id)

    timestamps()
  end

  @doc false
  def changeset(account_udt, attrs) do
    account_udt
    |> cast(attrs, [:account_id, :udt_id, :balance])
    |> validate_required([:account_id, :udt_id])
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

  def realtime_update_balance(account_id, udt_id) do
    result = from(au in AccountUDT,
      join: a in Account, on: a.id == au.account_id,
      where: au.account_id == ^account_id and au.udt_id == ^udt_id,
      select: %{short_address: a.short_address, balance: au.balance, updated_at: au.updated_at}
    ) |> Repo.one()

    case result do
      %{balance: balance, short_address: short_address, updated_at: updated_at} ->
        with second when second > 60 <- NaiveDateTime.diff(NaiveDateTime.utc_now |> NaiveDateTime.truncate(:second), updated_at),
          {:ok, on_chain_balance} <- GodwokenRPC.fetch_balance(short_address, udt_id),
          compare when compare != :eq <- Decimal.compare(Decimal.new(balance), Decimal.new(on_chain_balance)) do
            AccountUDT.create_or_update_account_udt!(%{
              account_id: account_id,
              udt_id: udt_id,
              balance: on_chain_balance
            })
            Decimal.new(on_chain_balance)
        else
          _ -> balance
        end
      nil ->
        Decimal.new(0)
    end
  end

  def sync_balance!(account_id, udt_id) do
    account = Repo.get(Account, account_id)
    {:ok, balance} = GodwokenRPC.fetch_balance(account.short_address, udt_id)

    AccountUDT.create_or_update_account_udt!(%{
      account_id: account.id,
      udt_id: udt_id,
      balance: balance
    })
    balance
  end

  def update_erc20_balance!(account_id, contract_account_id) do
    case UDT |> Repo.get_by(bridge_account_id: contract_account_id) do
      nil ->
        balance_of_method = "0x70a08231"
        contract_address = Repo.get(Account, contract_account_id).short_address
        user_address = Repo.get(Account, account_id).short_address
        case GodwokenRPC.eth_call(%{to: contract_address, data: balance_of_method <> String.duplicate("0", 24) <> String.slice(user_address, 2..-1)}) do
          {:ok, balance} ->
            number = balance |> hex_to_number
            AccountUDT.create_or_update_account_udt!(%{account_id: account_id, udt_id: contract_account_id, balance: number})
          {:error, _} ->
            nil
        end
      %UDT{id: udt_id, type: :bridge} ->
        sync_balance!(account_id, udt_id)
      _ ->
        Logger.error("may be type is not right #{contract_account_id}")
        nil
    end
  end
end
