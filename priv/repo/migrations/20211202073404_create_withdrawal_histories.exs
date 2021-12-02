defmodule GodwokenExplorer.Repo.Migrations.CreateWithdrawalHistories do
  use Ecto.Migration

  def change do
    create table(:withdrawal_histories) do
      add :layer1_block_number, :bigint
      add :layer1_tx_hash, :bytea
      add :layer1_output_index, :integer
      add :l2_script_hash, :bytea
      add :block_hash, :bytea
      add :block_number, :bigint
      add :udt_script_hash, :bytea
      add :sell_amount, :decimal
      add :sell_capacity, :decimal
      add :owner_lock_hash, :bytea
      add :payment_lock_hash, :bytea

      timestamps()
    end
    create unique_index("withdrawal_histories", [:layer1_tx_hash, :layer1_block_number, :layer1_output_index])
  end
end
