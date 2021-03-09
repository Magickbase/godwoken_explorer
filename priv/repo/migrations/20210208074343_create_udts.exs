defmodule GodwokenExplorer.Repo.Migrations.CreateUdts do
  use Ecto.Migration

  def change do
    create table(:udts) do
      add :name, :string
      add :symbol, :string
      add :decimal, :integer
      add :icon, :string
      add :supply, :decimal
      add :type_script, :jsonb
      add :script_hash, :bytea

      timestamps()
    end

  end
end
