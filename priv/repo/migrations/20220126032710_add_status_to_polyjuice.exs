defmodule GodwokenExplorer.Repo.Migrations.AddStatusToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuice) do
      add :status, :string
    end
  end
end
