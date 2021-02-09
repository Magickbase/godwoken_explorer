defmodule GodwokenExplorer.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :eth_address, :bytea
      add :lock_hash, :bytea
      add :nonce, :integer

      timestamps()
    end

  end
end
