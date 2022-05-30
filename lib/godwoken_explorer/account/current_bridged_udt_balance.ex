defmodule GodwokenExplorer.Account.CurrentBridgedUDTBalance do
  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Hash

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "account_current_udt_balances" do
    field(:value, :decimal)
    field(:value_fetched_at, :utc_datetime_usec)
    field(:layer1_block_number, :integer)
    field(:udt_script_hash, Hash.Full)
    field(:address_hash, Hash.Address)

    belongs_to(:account, GodwokenExplorer.Account, foreign_key: :account_id, references: :id)
    belongs_to(:udt, GodwokenExplorer.UDT, foreign_key: :udt_id, references: :id)

    timestamps()
  end

  @doc false
  def changeset(current_bridged_udt_balance, attrs) do
    current_bridged_udt_balance
    |> cast(attrs, [
      :value,
      :value_fetched_at,
      :layer1_block_number,
      :udt_id,
      :udt_script_hash,
      :address_hash,
      :account_id
    ])
    |> validate_required([:address_hash, :udt_script_hash])
    |> unique_constraint([:address_hash, :udt_script_hash])
  end

  def create

  def sync_balance!(%{script_hash: _script_hash, udt_id: nil}), do: {:error, :udt_not_exists}
  def sync_balance!(%{account_id: _account_id, udt_id: nil}), do: {:error, :udt_not_exists}

  def sync_balance!(%{script_hash: script_hash, udt_id: udt_id}) do
    with %Account{id: account_id, eth_address: eth_address, registry_address: registry_address} <-
           Repo.get_by(Account, script_hash: script_hash),
         %Account{script_hash: script_hash} <- Repo.get(Account, udt_id) do
      {:ok, balance} = GodwokenRPC.fetch_balance(registry_address, udt_id)

      CurrentBridgedUDTBalance.create_or_update_account_udt!(%{
        account_id: account_id,
        address_hash: eth_address,
        udt_id: udt_id,
        token_contract_address_hash: to_string(script_hash),
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
        token_contract_address_hash: to_string(script_hash),
        balance: balance
      })
    else
      _ ->
        {:error, :account_not_exist}
    end
  end
end
