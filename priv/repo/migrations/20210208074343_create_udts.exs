defmodule GodwokenExplorer.Repo.Migrations.CreateUdts do
  use Ecto.Migration

  def change do
    create table(:udts) do
      add :name, :string
      add :symbol, :string
      add :decimal, :integer
      add :typescript_hash, :bytea

      timestamps()
    end

  end
end
