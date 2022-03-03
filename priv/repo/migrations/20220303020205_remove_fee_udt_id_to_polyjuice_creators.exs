defmodule GodwokenExplorer.Repo.Migrations.RemoveFeeUDTIdToPolyjuiceCreators do
  use Ecto.Migration

  def change do
    alter table(:polyjuice_creators) do
      remove :fee_udt_id
    end
  end
end
