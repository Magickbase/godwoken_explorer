defmodule GodwokenExplorer.Repo.Migrations.AlterUdtsWithCreatedCountBurntCount do
  use Ecto.Migration

  def change do
    alter table("udts") do
      add :created_count, :decimal
      add :burnt_count, :decimal
    end
  end
end
