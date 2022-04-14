defmodule GodwokenExplorer.Repo.Migrations.AddTransactionIndexToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :index, :integer
    end
  end
end
