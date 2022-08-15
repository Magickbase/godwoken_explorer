defmodule GodwokenExplorer.TokenApproval do
  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.Hash

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "token_approvals" do
    field :block_hash, Hash.Full
    field :block_number, :integer
    field :transaction_hash, Hash.Full
    field(:token_owner_address_hash, Hash.Address)
    field(:spender_address_hash, Hash.Address)
    field(:token_contract_address_hash, Hash.Address)
    field(:data, :decimal)
    field(:approved, :boolean)
    field(:type, Ecto.Enum, values: [:approval, :approval_all])

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
      :type
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
    |> unique_constraint([
      :token_owner_address_hash,
      :spender_address_hash,
      :token_contract_address_hash,
      :data,
      :type
    ])
  end
end
