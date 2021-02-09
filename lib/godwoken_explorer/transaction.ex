defmodule GodwokenExplorer.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:hash, :binary, autogenerate: false}
  schema "transactions" do
    field :args, :binary
    field :from_account_id, :integer
    field :nonce, :integer
    field :status, Ecto.Enum, values: [:unfinalized, :finalized]
    field :to_account_id, :integer
    field :type, :string

    belongs_to(:block, GodwokenExplorer.Block, foreign_key: :block_hash, references: :hash)

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:hash, :block_hash, :type, :from_account_id, :to_account_id, :nonce, :args, :status])
    |> validate_required([:hash, :from_account_id, :to_account_id, :nonce, :args, :status])
  end
end
