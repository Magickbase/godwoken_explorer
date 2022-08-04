defmodule GodwokenExplorer.Repo.Migrations.AddSkipMetadataToUdts do
  use Ecto.Migration

  def change do
    alter table(:udts) do
      add :skip_metadata, :boolean, null: true
    end
  end
end
