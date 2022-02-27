defmodule GodwokenExplorer.Repo.Migrations.AddBlockNumberIndexToTransaction do
  use Ecto.Migration

  def change do
    create index(:transactions, :block_number)
  end
end
