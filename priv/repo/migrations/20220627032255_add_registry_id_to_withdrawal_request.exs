defmodule GodwokenExplorer.Repo.Migrations.AddRegistryIDToWithdrawalRequest do
  use Ecto.Migration

  def change do
    alter table(:withdrawal_requests) do
      add :registry_id, :integer
    end
  end
end
