defmodule GodwokenExplorer.Repo.Migrations.CreateDepositHistories do
  use Ecto.Migration

  def change do
    create table(:deposit_histories) do
      add :script_hash, :bytea
      add :ckb_lock_hash, :bytea
      add :layer1_block_number, :bigint
      add :layer1_tx_hash, :bytea
      add :layer1_output_index, :integer
      add :udt_id, :integer
      add :amount, :decimal

      timestamps()
    end

  end
end
