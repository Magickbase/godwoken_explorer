defmodule GodwokenExplorer.Repo.Migrations.DropPendingTransaction do
  use Ecto.Migration

  def change do
    drop table(:pending_transactions)
  end
end
