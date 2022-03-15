defmodule GodwokenExplorer.Repo.Migrations.AddEthHashToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :eth_hash, :bytea
    end
  end
end
