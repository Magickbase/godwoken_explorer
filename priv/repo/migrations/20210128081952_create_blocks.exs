defmodule GodwokenExplorer.Repo.Migrations.CreateBlocks do
  use Ecto.Migration

  def change do
    create table(:blocks, primary_key: false) do
      add :hash, :bytea, null: false, primary_key: true
      add :number, :bigint, null: false
      add :parent_hash, :bytea
      add :timestamp, :utc_datetime_usec, null: false
      add :miner_id, :bytea, null: false
      add :finalized_tx_hash, :bytea
      add :finalized_at, :utc_datetime_usec
      add :transaction_count, :integer, null: false, default: 0

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(index(:blocks, [:hash], unique: true))
    create(index(:blocks, [:number], unique: true))
  end
end
