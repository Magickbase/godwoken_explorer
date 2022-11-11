defmodule GodwokenExplorer.Repo.Migrations.AddUANAndDisplayNameToUDTs do
  use Ecto.Migration

  def change do
    alter table(:udts) do
      add :uan, :string
      add :display_name, :string
    end
  end
end
