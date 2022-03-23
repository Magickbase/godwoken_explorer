defmodule GodwokenExplorer.Repo.Migrations.CreateKeyValues do
  use Ecto.Migration

  def change do
    create table(:key_values) do
      add :key, :string
      add :value, :string

      timestamps()
    end
  end
end
