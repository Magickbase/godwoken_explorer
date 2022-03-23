defmodule GodwokenExplorer.Repo.Migrations.AddUniqueIndexToKeyValues do
  use Ecto.Migration

  def change do
    create(index(:key_values, [:key], unique: true))
  end
end
