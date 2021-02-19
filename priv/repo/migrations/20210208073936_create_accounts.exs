defmodule GodwokenExplorer.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :eth_address, :bytea
      add :ckb_address, :bytea
      add :lock_hash, :bytea
      add :nonce, :integer
      add :type, :string
      add :layer2_tx, :bytea

      timestamps()
    end
  end
end
