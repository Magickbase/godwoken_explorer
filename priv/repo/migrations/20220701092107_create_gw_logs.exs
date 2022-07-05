defmodule GodwokenExplorer.Repo.Migrations.CreateGwLogs do
  use Ecto.Migration

  def change do
    create table(:gw_logs, primary_key: false) do
      add :transaction_hash, :bytea, primary_key: true
      add :account_id, :integer
      add :service_flag, :integer
      add :data, :bytea
      add :type, :string
      add :index, :integer, primary_key: true

      timestamps()
    end
  end
end
