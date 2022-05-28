defmodule GodwokenExplorer.Account.UDTBalance do
  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.Hash

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "account_udt_balances" do
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
    |> unique_constraint([:address_hash, :token_contract_address_hash, :block_number])
  end
end
