defmodule GodwokenExplorer.Repo.Migrations.AddAccountIDUniqueIndexToSmartContract do
  use Ecto.Migration

  def change do
    create(unique_index(:smart_contracts, [:account_id]))
  end
end
