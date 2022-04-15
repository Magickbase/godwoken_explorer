defmodule GodwokenExplorer.Repo.Migrations.RemoveUnusedIndexs do
  use Ecto.Migration

  def change do
    drop index(:transactions, :inserted_at)
    drop index(:logs, :inserted_at)
    drop index(:token_transfers, :inserted_at)

    create index(:transactions, :block_number)
  end
end
