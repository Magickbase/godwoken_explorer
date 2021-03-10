defmodule GodwokenExplorer.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :integer, null: false, primary_key: true
      add :ckb_address, :bytea
      add :ckb_lock_script, :jsonb
      add :eth_address, :bytea
      add :script_hash, :bytea
      add :script, :jsonb
      add :nonce, :integer, default: 0
      add :type, :string
      add :layer2_tx, :bytea

      timestamps()
    end
  end
end
