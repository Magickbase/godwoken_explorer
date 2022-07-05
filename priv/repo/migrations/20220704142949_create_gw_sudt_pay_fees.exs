defmodule GodwokenExplorer.Repo.Migrations.CreateGwSudtPayFees do
  use Ecto.Migration

  def change do
    create table(:gw_sudt_pay_fees, primary_key: false) do
      add :transaction_hash, :bytea, primary_key: true
      add :log_index, :integer, primary_key: true
      add :udt_id, :integer
      add :from_address, :bytea
      add :from_registry_id, :integer
      add :block_producer_address, :bytea
      add :block_producer_registry_id, :integer
      add :amount, :decimal

      timestamps()
    end
  end
end
