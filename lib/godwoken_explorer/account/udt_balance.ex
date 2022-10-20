defmodule GodwokenExplorer.Account.UDTBalance do
  @moduledoc """
  Represents a token balance from an address.

  In this table we can see all token balances that a specific addreses had acording to the block
  numbers. If you want to show only the last balance from an address, consider querying against
  `Account.CurrentUDTBalance` instead.
  """

  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.Chain

  @typedoc """
   *  `address_hash` - The `t:GowokenExplorer.Chain.Address.t/0` that is the balance's owner.
   *  `udt` - The `t:GodwokenExplorer.UDT.t/0` that is the balance's udt
   *  `udt_id` - The udt foreign key.
   *  `account` - The `t:GodwokenExplorer.Account.t/0` that is the balance's account
   *  `account_id` - The account foreign key.
   *  `token_contract_address_hash` - The contract address hash foreign key.
   *  `block_number` - The block's number that the transfer took place.
   *  `value` - The value that's represents the balance.
   *  `value_fetched_at` - The time that fetch udt balance.
   *  `token_id` - The token_id of the transferred token (applicable for ERC-1155 and ERC-721 tokens)
   *  `token_type` - The type of the token
  """
  @type t :: %__MODULE__{
          address_hash: Hash.Address.t(),
          udt: %Ecto.Association.NotLoaded{} | UDT.t(),
          udt_id: non_neg_integer(),
          account: %Ecto.Association.NotLoaded{} | Account.t(),
          account_id: non_neg_integer(),
          token_contract_address_hash: Hash.Address,
          block_number: Block.block_number(),
          value: Decimal.t() | nil,
          value_fetched_at: DateTime.t(),
          token_id: non_neg_integer() | nil,
          token_type: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

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
          (is_nil(ub.value_fetched_at) or is_nil(ub.value)) and
          (not is_nil(ub.token_type) and (ub.token_type == :erc20 or ub.token_type == :erc721)),
      or_where:
        ub.address_hash != ^@burn_address_hash and
          (is_nil(ub.value_fetched_at) or is_nil(ub.value)) and
          (not is_nil(ub.token_id) and ub.token_type == :erc1155)
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
