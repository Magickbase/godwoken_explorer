defmodule GodwokenExplorer.Repo.Migrations.AddInsertedAtIndexToTokenTransfers do
  use Ecto.Migration

  def change do
    create index(:token_transfers, :inserted_at)
  end
end
