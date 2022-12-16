defmodule GodwokenExplorer.Repo.Migrations.AddBitAliasToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :bit_alias, :string
    end
  end
end
