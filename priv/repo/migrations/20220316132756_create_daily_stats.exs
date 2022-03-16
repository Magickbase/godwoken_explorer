defmodule GodwokenExplorer.Repo.Migrations.CreateDailyStats do
  use Ecto.Migration

  def change do
    create table(:daily_stats) do
      add :date, :date
      add :total_txn, :integer
      add :avg_block_time, :float
      add :avg_block_size, :integer
      add :avg_gas_used, :decimal
      add :avg_gas_limit, :decimal
      add :total_block_count, :integer
      add :erc20_transfer_count, :integer

      timestamps()
    end
    create(index(:daily_stats, [:date], unique: true))
  end
end
