defmodule GodwokenExplorer.AccountUdt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "account_udts" do
    field :balance, :decimal
    belongs_to(:account, GodwokenExplorer.Account, foreign_key: :account_id, references: :id)
    belongs_to(:udt, GodwokenExplorer.Udt, foreign_key: :udt_id, references: :id)

    timestamps()
  end

  @doc false
  def changeset(account_udt, attrs) do
    account_udt
    |> cast(attrs, [:account_id, :udt_id, :balance])
    |> validate_required([:account_id, :udt_id, :balance])
  end
end
