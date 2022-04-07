defmodule GodwokenExplorer.Repo.Migrations.ChangeUdtDescriptionType do
  use Ecto.Migration

  def change do
    alter table(:udts) do
      modify :description, :text
    end
  end
end
