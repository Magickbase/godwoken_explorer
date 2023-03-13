defmodule GodwokenExplorer.ERC721Token do
  @moduledoc """
  Represents ERC 721 token with it's owner.
  ERC-721: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.
  """

  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.{Hash}
  alias GodwokenExplorer.ERC721Token

  @typedoc """
  * `token_contract_address_hash` - Address hash foreign key
  * `token_id` - ID of the token
  * `address_hash` - nft owner address hash
  * `block_number` - last update block number
  """

  @type t :: %ERC721Token{
          token_contract_address_hash: Hash.Address.t(),
          token_id: non_neg_integer(),
          address_hash: Hash.Address.t(),
          block_number: non_neg_integer()
        }

  @primary_key false
  schema "erc721_tokens" do
    field(:token_contract_address_hash, Hash.Address, primary_key: true)
    field(:token_id, :decimal, primary_key: true)
    field(:address_hash, Hash.Address)
    field(:block_number, :integer)
    field(:value, :decimal, virtual: true)
    field(:token_type, Ecto.Enum, values: [:erc20, :erc721, :erc1155], virtual: true)

    belongs_to(:udt_of_address, GodwokenExplorer.UDT,
      foreign_key: :token_contract_address_hash,
      references: :contract_address_hash,
      define_field: false
    )

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(%ERC721Token{} = instance, params \\ %{}) do
    instance
    |> cast(params, [:token_contract_address_hash, :token_id, :address_hash, :block_number])
    |> validate_required([:token_contract_address_hash, :token_id, :address_hash, :block_number])
    |> unique_constraint([:token_contract_address_hash, :token_id])
  end
end
