defmodule GodwokenExplorer.Repo.Migrations.CreateGwLogs do
  use Ecto.Migration

  def change do
    create table(:gw_logs) do
      add :transaction_hash, :bytea
      add :account_id, :integer
      add :service_flag, :integer
      add :data, :bytea
      add :type, :string

      timestamps()
    end
  end
end
