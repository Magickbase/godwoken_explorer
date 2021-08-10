defmodule GodwokenExplorer.Repo.Migrations.CreateWithdrawals do
  use Ecto.Migration

  def change do
    create table(:withdrawals) do
      add :tx_hash, :binary
      add :account_script_hash, :binary
      add :amount, :decimal
      add :capacity, :decimal
      add :owner_lock_hash, :binary
      add :payment_lock_hash, :binary
      add :sell_amount, :decimal
      add :sell_capacity, :decimal
      add :sudt_script_hash, :binary
      add :udt_id, :integer
      add :fee_amount, :decimal
      add :fee_udt_id, :integer

      timestamps()
    end

  end
end
