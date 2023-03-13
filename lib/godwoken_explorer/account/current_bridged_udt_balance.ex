defmodule GodwokenExplorer.Account.CurrentBridgedUDTBalance do
  @moduledoc """
  A account's newest balance of layer1 bridge token.

  In this table you want to get account's bridge token that deposit or withdraw from layer1.
  If you want to get bridge token's proxy layer2 native token, you need to query from `GodwokenExplorer.Account.CurrentUDTBalance`.
  So to get a account's newest token balance, you need to compare above two table's data and sort by timestamp then get the latest value.
  [Bridged token list](https://github.com/godwokenrises/godwoken-info/blob/main/mainnet_v1/bridged-token-list.json)
  """

  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.Hash

  @typedoc """
   *  `address_hash` - The `t:GowokenExplorer.Chain.Address.t/0` that is the balance's owner.
   *  `udt_id` - The udt foreign key.
   *  `account_id` - The account foreign key.
   *  `udt_script_hash` - layer2 udt account script hash.
   *  `block_number` - The layer2 block's number that the transfer took place.
   *  `layer1_block_number` - The layer1 block's number that the transfer took place.
   *  `value` - The value that's represents the balance.
   *  `value_fetched_at` - The time that fetch udt balance.
   *  `uniq_id` - The token's layer2 native token id
  """
  @type t :: %__MODULE__{
          address_hash: Hash.Address.t(),
          udt: %Ecto.Association.NotLoaded{} | UDT.t(),
          udt_id: non_neg_integer(),
          account: %Ecto.Association.NotLoaded{} | Account.t(),
          account_id: non_neg_integer(),
          block_number: non_neg_integer(),
          value: Decimal.t() | nil,
          value_fetched_at: DateTime.t(),
          layer1_block_number: non_neg_integer(),
          uniq_id: non_neg_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "account_current_bridged_udt_balances" do
    field(:value, :decimal)
    field(:value_fetched_at, :utc_datetime_usec)
    field(:layer1_block_number, :integer)
    field(:block_number, :integer)
    # layer2 udt account script hash
    field(:udt_script_hash, Hash.Full)
    field(:address_hash, Hash.Address)

    belongs_to(:account, GodwokenExplorer.Account, foreign_key: :account_id, references: :id)
    belongs_to(:udt, GodwokenExplorer.UDT, foreign_key: :udt_id, references: :id)

    field :uniq_id, :integer, virtual: true

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(current_bridged_udt_balance, attrs) do
    current_bridged_udt_balance
    |> cast(attrs, [
      :value,
      :value_fetched_at,
      :layer1_block_number,
      :block_number,
      :udt_id,
      :udt_script_hash,
      :address_hash,
      :account_id
    ])
    |> validate_required([:address_hash, :udt_script_hash])
    |> unique_constraint([:address_hash, :udt_script_hash])
  end

  def create_or_update!(attrs) do
    case Repo.get_by(__MODULE__, %{
           address_hash: attrs[:address_hash],
           udt_script_hash: attrs[:udt_script_hash]
         }) do
      nil -> %__MODULE__{}
      bridged_udt_balance -> bridged_udt_balance
    end
    |> changeset(attrs)
    |> Repo.insert_or_update!()
  end

  def sync_balance!(%{
        script_hash: _script_hash,
        udt_id: nil,
        layer1_block_number: _layer1_block_number
      }),
      do: {:error, :udt_not_exists}

  def sync_balance!(%{
        account_id: _account_id,
        udt_id: nil,
        layer1_block_number: _layer1_block_number
      }),
      do: {:error, :udt_not_exists}

  def sync_balance!(%{
        script_hash: script_hash,
        udt_id: udt_id,
        layer1_block_number: layer1_block_number
      }) do
    with %Account{id: account_id, eth_address: eth_address, registry_address: registry_address} <-
           Repo.get_by(Account, script_hash: script_hash),
         %Account{script_hash: script_hash} <- Repo.get(Account, udt_id) do
      {:ok, balance} = GodwokenRPC.fetch_balance(registry_address, udt_id)

      __MODULE__.create_or_update!(%{
        account_id: account_id,
        address_hash: eth_address,
        udt_id: udt_id,
        udt_script_hash: to_string(script_hash),
        value: balance,
        layer1_block_number: layer1_block_number
      })
    else
      _ ->
        {:error, :account_not_exist}
    end
  end

  def sync_balance!(%{
        account_id: account_id,
        udt_id: udt_id,
        layer1_block_number: layer1_block_number
      }) do
    with %Account{eth_address: eth_address, registry_address: registry_address} <-
           Repo.get(Account, account_id),
         %Account{script_hash: script_hash} <- Repo.get(Account, udt_id) do
      {:ok, balance} = GodwokenRPC.fetch_balance(registry_address, udt_id)

      __MODULE__.create_or_update!(%{
        account_id: account_id,
        address_hash: eth_address,
        udt_id: udt_id,
        udt_script_hash: to_string(script_hash),
        value: balance,
        layer1_block_number: layer1_block_number
      })
    else
      _ ->
        {:error, :account_not_exist}
    end
  end
end
