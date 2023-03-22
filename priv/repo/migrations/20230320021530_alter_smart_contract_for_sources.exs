defmodule GodwokenExplorer.Repo.Migrations.AlterSmartContractForSources do
  use Ecto.Migration

  def change do
    alter table(:smart_contracts) do
      add(:sourcify_metadata, :map)
    end
  end
end
