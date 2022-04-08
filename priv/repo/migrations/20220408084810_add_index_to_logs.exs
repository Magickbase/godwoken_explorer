defmodule GodwokenExplorer.Repo.Migrations.AddIndexToLogs do
  use Ecto.Migration

  def change do
    create index(:logs, :inserted_at)
    create index(:logs, :block_number)
  end
end
