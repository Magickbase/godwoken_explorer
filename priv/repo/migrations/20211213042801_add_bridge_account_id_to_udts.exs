defmodule GodwokenExplorer.Repo.Migrations.AddBridgeAccountIdToUdts do
  use Ecto.Migration

  def change do
    alter table(:udts) do
      add :bridge_account_id, :integer
    end
  end
end
