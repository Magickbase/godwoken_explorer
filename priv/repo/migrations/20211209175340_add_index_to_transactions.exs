defmodule GodwokenExplorer.Repo.Migrations.AddIndexToTransactions do
  use Ecto.Migration

  def change do
    create index(:transactions, :from_account_id)
    create index(:transactions, :to_account_id)
    create index(:polyjuice, :tx_hash)
  end
end
