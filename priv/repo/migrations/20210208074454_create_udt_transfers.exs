defmodule GodwokenExplorer.Repo.Migrations.CreateUdtTransfers do
  use Ecto.Migration

  def change do
    create table(:udt_transfers) do
      add :tx_hash, :bytea
      add :udt_id, :integer
      add :amount, :decimal
      add :fee, :decimal

      timestamps()
    end

  end
end
