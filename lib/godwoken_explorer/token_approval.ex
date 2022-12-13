defmodule GodwokenExplorer.TokenApproval do
  @moduledoc """
  Token approved records.

  We can parse these info from logs.
  """
  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.Hash

  alias GodwokenExplorer.Block
  alias GodwokenExplorer.UDT

  @typedoc """
     * `token_owner_address_hash` - Token owner.
     * `spender_address_hash` - User approve token to which address.
     * `token_contract_address_hash` - Which token contract.
     * `data` - ERC721 token id.
     * `approved` - Approve operation or Cancel approval.
     * `type` - Approve or approve_all.
     * `token_type` - ERC20 ERC721 or ERC1155.
     * `block_hash` - Layer2 block.
     * `transaction_hash` - Layer2 transaction.
  """

  @type t :: %__MODULE__{
          token_owner_address_hash: Hash.Address.t(),
          spender_address_hash: binary(),
          token_contract_address_hash: Hash.Address.t(),
          data: Decimal.t(),
          approved: boolean(),
          type: String.t(),
          token_type: String.t(),
          block_number: non_neg_integer(),
          block_hash: Hash.Full.t(),
          transaction_hash: Hash.Full.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @derive {Jason.Encoder, except: [:__meta__]}
  schema "token_approvals" do
    field :block_number, :integer
    field :transaction_hash, Hash.Full
    field :token_owner_address_hash, Hash.Address
    field :spender_address_hash, :binary
    field :data, :decimal
    field :approved, :boolean
    field :type, Ecto.Enum, values: [:approval, :approval_all]
    field :token_type, Ecto.Enum, values: [:erc20, :erc721]

    belongs_to(:block, Block,
      foreign_key: :block_hash,
      references: :hash,
      type: Hash.Full
    )

    belongs_to(:udt, UDT,
      foreign_key: :token_contract_address_hash,
      references: :contract_address_hash,
      type: Hash.Address
    )

    timestamps()
  end

  @doc false
  def changeset(withdrawal_history, attrs) do
    withdrawal_history
    |> cast(attrs, [
      :block_hash,
      :block_number,
      :transaction_hash,
      :token_owner_address_hash,
      :spender_address_hash,
      :token_contract_address_hash,
      :data,
      :approved,
      :type,
      :token_type
    ])
    |> validate_required([
      :block_hash,
      :block_number,
      :transaction_hash,
      :token_owner_address_hash,
      :spender_address_hash,
      :token_contract_address_hash,
      :data,
      :approved,
      :type
    ])
  end
end
