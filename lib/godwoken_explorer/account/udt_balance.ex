defmodule GodwokenExplorer.Account.UDTBalance do
  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.Chain

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "account_udt_balances" do
    field :value, :decimal
    field(:value_fetched_at, :utc_datetime_usec)
    field(:block_number, :integer)
    field :address_hash, Hash.Address
    field :token_contract_address_hash, Hash.Address
    belongs_to(:account, GodwokenExplorer.Account, foreign_key: :account_id, references: :id)
    belongs_to(:udt, GodwokenExplorer.UDT, foreign_key: :udt_id, references: :id)

    timestamps(type: :utc_datetime_usec)
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

  {:ok, burn_address_hash} =
    Chain.string_to_address_hash("0x0000000000000000000000000000000000000000")

  @burn_address_hash burn_address_hash

  def unfetched_udt_balances do
    from(
      ub in UDTBalance,
      where:
        ub.address_hash != ^@burn_address_hash and
          (is_nil(ub.value_fetched_at) or is_nil(ub.value))
    )
  end
end
