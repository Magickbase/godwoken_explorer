defmodule GodwokenExplorer.Withdrawal do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  schema "withdrawals" do
    field :account_script_hash, :binary
    field :amount, :decimal
    field :capacity, :decimal
    field :owner_lock_hash, :binary
    field :payment_lock_hash, :binary
    field :sell_amount, :decimal
    field :sell_capacity, :decimal
    field :sudt_script_hash, :binary
    field :tx_hash, :binary
    field :udt_id, :integer
    field :fee_amount, :decimal
    field :fee_udt_id, :integer

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :tx_hash,
      references: :hash,
      define_field: false
    )

    belongs_to(:udt, GodwokenExplorer.UDT,
      foreign_key: :udt_id,
      references: :id,
      define_field: false
    )

    timestamps()
  end

  @doc false
  def changeset(withdrawal, attrs) do
    withdrawal
    |> cast(attrs, [
      :account_script_hash,
      :amount,
      :capacity,
      :owner_lock_hash,
      :payment_lock_hash,
      :sell_amount,
      :sell_capacity,
      :sudt_script_hash,
      :udt_id
    ])
    |> validate_required([
      :account_script_hash,
      :amount,
      :capacity,
      :owner_lock_hash,
      :payment_lock_hash,
      :sell_amount,
      :sell_capacity,
      :sudt_script_hash,
      :udt_id
    ])
  end

  def create_withdrawal(attrs) do
    %Withdrawal{}
    |> Withdrawal.changeset(attrs)
    |> Ecto.Changeset.put_change(:tx_hash, attrs[:hash])
    |> Ecto.Changeset.put_change(:udt_id, attrs[:udt_id])
    |> Repo.insert()
  end
end
