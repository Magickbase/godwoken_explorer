defmodule GodwokenExplorer.Repo.Migrations.AddEthHashToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :eth_hash, :bytea
    end

    create(index(:transactions, [:eth_hash], unique: true))
  end
end
