defmodule GodwokenExplorer.Repo.Migrations.RemoveCkbColumnFromAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      remove :ckb_address
      remove :ckb_lock_script
      remove :ckb_lock_hash
      remove :layer2_tx
    end
  end
end
