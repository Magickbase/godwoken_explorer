defmodule GodwokenExplorer.Repo.Migrations.AddTypeToUdts do
  use Ecto.Migration

  def change do
    alter table(:udts) do
      add :price, :decimal
      add :value, :decimal
      add :description, :string
      add :official_site, :string
      add :type, :string, default: "bridge"
    end
  end
end
