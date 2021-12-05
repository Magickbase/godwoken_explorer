defmodule GodwokenExplorer.PendingTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:hash, :binary, autogenerate: false}
  schema "pending_transactions" do
    field :args, :binary
    field :from_account_id, :integer
    field :nonce, :integer
    field :to_account_id, :integer
    field :type, Ecto.Enum, values: [:sudt, :polyjuice_creator, :polyjuice]
    field :parsed_args, :map

    timestamps()
  end

  @doc false
  def changeset(pending_transaction, attrs) do
    pending_transaction
    |> cast(attrs, [:hash, :from_account_id, :to_account_id, :nonce, :args])
    |> validate_required([:hash, :from_account_id, :to_account_id, :nonce, :args])
  end
end
