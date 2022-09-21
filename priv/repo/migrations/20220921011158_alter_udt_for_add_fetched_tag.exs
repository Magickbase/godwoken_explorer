defmodule GodwokenExplorer.Repo.Migrations.AlterUdtForAddFetchedTag do
  use Ecto.Migration

  def change do
    alter table(:udts) do
      add :is_fetched, :boolean, null: true
    end
  end
end
