defmodule GodwokenExplorer.Repo.Migrations.AddInsertedAtIndexToTransactions do
  use Ecto.Migration

  def change do
    create index(:transactions, :inserted_at)
  end
end
