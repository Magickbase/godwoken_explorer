defmodule GodwokenExplorer.Repo.Migrations.AddBlockNumberIndexToTransactions do
  use Ecto.Migration

  def change do
    create index(:transactions, [:block_number, :status])
  end
end
