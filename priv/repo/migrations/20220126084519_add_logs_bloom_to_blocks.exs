defmodule GodwokenExplorer.Repo.Migrations.AddLogsBloomToBlocks do
  use Ecto.Migration

  def change do
    alter table(:blocks) do
      add :logs_bloom, :bytea
    end
  end
end
