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
end
