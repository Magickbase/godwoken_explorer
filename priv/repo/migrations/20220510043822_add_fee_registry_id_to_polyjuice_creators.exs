defmodule GodwokenExplorer.Repo.Migrations.AddFeeRegistryIdToPolyjuiceCreators do
  use Ecto.Migration

  def change do
    alter table(:polyjuice_creators) do
      add :fee_registry_id, :integer
    end
  end
end
