defmodule GodwokenExplorer.Repo.Migrations.AddCkbLockHashToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add(:ckb_lock_hash, :bytea)
    end
  end
end
