defmodule GodwokenExplorer.Repo.Migrations.CreatePoyjuiceUniqueIndex do
  use Ecto.Migration

  def change do
    drop index(:polyjuice, :tx_hash)

    create(index(:polyjuice, [:tx_hash], unique: true))
    create(index(:withdrawal_requests, [:account_script_hash, :nonce], unique: true))
  end
end
