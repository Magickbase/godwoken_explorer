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

    field :token_id, :decimal
    field :token_type, Ecto.Enum, values: [:erc20, :erc721, :erc1155]

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
      :block_number,
      :token_id,
      :token_type
    ])
    |> validate_required(~w(address_hash block_number token_contract_address_hash token_type)a)

    # |> unique_constraint([:address_hash, :token_contract_address_hash, :block_number])
  end

  {:ok, burn_address_hash} =
    Chain.string_to_address_hash("0x0000000000000000000000000000000000000000")

  @burn_address_hash burn_address_hash

  def minted_burn_address_hash() do
    @burn_address_hash
  end

  def unfetched_udt_balances do
    from(
      ub in UDTBalance,
      where:
        ub.address_hash != ^@burn_address_hash and
          (is_nil(ub.value_fetched_at) or is_nil(ub.value))
    )
  end

  def snapshot_for_token(start_block_number, end_block_number, token_contract_address_hash) do
    base_query =
      from(cub in UDTBalance,
        where:
          cub.block_number >= ^start_block_number and cub.block_number <= ^end_block_number and
            cub.token_contract_address_hash == ^token_contract_address_hash,
        select: %{address_hash: cub.address_hash, value: cub.value},
        distinct: cub.address_hash,
        order_by: [desc: cub.block_number]
      )

    from(q in subquery(base_query), where: q.value != 0) |> Repo.all()
  end
end
