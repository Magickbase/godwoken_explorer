defmodule GodwokenExplorer.Repo.Migrations.RemoveShortAddressToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      remove :short_address
      add :registry_address, :bytea
    end
  end
end
