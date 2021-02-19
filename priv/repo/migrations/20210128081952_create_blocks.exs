defmodule GodwokenExplorer.Repo.Migrations.CreateBlocks do
  use Ecto.Migration

  def change do
    create table(:blocks, primary_key: false) do
      add :hash, :bytea, null: false, primary_key: true
      add :number, :bigint, null: false
      add :parent_hash, :bytea
      add :timestamp, :utc_datetime_usec, null: false
      add :status, :string, null: false
      add :aggregator_id, :int, null: false
      add :transaction_count, :integer, null: false, default: 0
      add :layer1_tx_hash, :bytea
      add :layer1_block_number, :bigint
      add :size, :integer
      add :tx_fees, :integer
      add :average_gas_price, :decimal

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(index(:blocks, [:hash], unique: true))
    create(index(:blocks, [:number], unique: true))
  end
end
