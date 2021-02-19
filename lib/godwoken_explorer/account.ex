defmodule GodwokenExplorer.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "accounts" do
    field :eth_address, :binary
    field :ckb_address, :binary
    field :lock_hash, :binary
    field :nonce, :integer
    field :type, Ecto.Enum, values: [:user, :polyjuice_root, :contract]
    field :layer2_tx, :binary
    has_many :account_udts, GodwokenExplorer.AccountUdt

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:eth_address, :ckb_address, :lock_hash, :nonce, :type, :layer2_tx])
    |> validate_required([:eth_address, :lock_hash, :nonce, :type])
  end
end
